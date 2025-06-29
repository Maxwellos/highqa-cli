#!/bin/bash

# HighQA CLI Tool - Shell Script Version
# 移动端自动化测试平台命令行工具
# Version: 1.0.0
# Author: HighQA Team

set -euo pipefail  # 严格模式：遇到错误退出、未定义变量退出、管道错误退出

# =============================================================================
# 配置和常量
# =============================================================================

# 默认配置
DEFAULT_API_URL="https://api.highqa.com"
DEFAULT_TIMEOUT=1800
DEFAULT_RETRY_COUNT=3
DEFAULT_OUTPUT_FORMAT="json"

# 颜色配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志级别
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# =============================================================================
# 工具函数
# =============================================================================

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${timestamp} ${RED}[ERROR]${NC} $message" >&2
            ;;
        WARN)
            echo -e "${timestamp} ${YELLOW}[WARN]${NC} $message" >&2
            ;;
        INFO)
            echo -e "${timestamp} ${BLUE}[INFO]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${timestamp} ${GREEN}[SUCCESS]${NC} $message"
            ;;
        DEBUG)
            if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
                echo -e "${timestamp} [DEBUG] $message" >&2
            fi
            ;;
    esac
}

# 错误处理函数
error_exit() {
    log ERROR "$1"
    exit 1
}

# 检查依赖
check_dependencies() {
    local deps=("curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error_exit "$dep 未安装，请先安装 $dep"
        fi
    done
}

# 检查配置
check_config() {
    if [[ -z "${HIGHQA_TOKEN:-}" ]]; then
        error_exit "HIGHQA_TOKEN 环境变量未设置"
    fi
    
    if [[ -z "${HIGHQA_API_URL:-}" ]]; then
        export HIGHQA_API_URL="$DEFAULT_API_URL"
        log WARN "使用默认API地址: $HIGHQA_API_URL"
    fi
}

# HTTP请求函数
api_request() {
    local method=$1
    local endpoint=$2
    local data=${3:-""}
    
    local url="${HIGHQA_API_URL}${endpoint}"
    local response_file=$(mktemp)
    local http_code
    
    log DEBUG "发送 $method 请求到: $url"
    
    if [[ -n "$data" ]]; then
        http_code=$(curl -s -w "%{http_code}" \
            -X "$method" \
            -H "Authorization: Bearer $HIGHQA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url" -o "$response_file")
    else
        http_code=$(curl -s -w "%{http_code}" \
            -X "$method" \
            -H "Authorization: Bearer $HIGHQA_TOKEN" \
            "$url" -o "$response_file")
    fi
    
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        cat "$response_file"
        rm -f "$response_file"
        return 0
    else
        log ERROR "API请求失败，HTTP状态码: $http_code"
        cat "$response_file" >&2
        rm -f "$response_file"
        return 1
    fi
}

# 等待测试完成
wait_for_completion() {
    local suite_id=$1
    local timeout=${2:-$DEFAULT_TIMEOUT}
    local check_interval=30
    local elapsed=0
    
    log INFO "等待测试套件 $suite_id 完成..."
    
    while [[ $elapsed -lt $timeout ]]; do
        local status_response
        status_response=$(api_request GET "/api/v1/testsuites/$suite_id")
        
        local status
        status=$(echo "$status_response" | jq -r '.data.status')
        
        case $status in
            "completed"|"success")
                log SUCCESS "测试套件执行完成"
                echo "$status_response"
                return 0
                ;;
            "failed"|"error")
                log ERROR "测试套件执行失败"
                echo "$status_response"
                return 1
                ;;
            "running"|"pending"|"queued")
                log INFO "测试进行中... 状态: $status (已等待 ${elapsed}s)"
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
            *)
                log WARN "未知状态: $status"
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
        esac
    done
    
    log ERROR "等待超时 (${timeout}s)"
    return 1
}

# =============================================================================
# 核心功能函数
# =============================================================================

# 认证
auth_login() {
    local token=$1
    export HIGHQA_TOKEN="$token"
    
    # 验证token
    if api_request GET "/api/v1/auth/verify" > /dev/null; then
        log SUCCESS "认证成功"
        return 0
    else
        log ERROR "认证失败，请检查token是否正确"
        return 1
    fi
}

# 创建测试套件
create_testsuite() {
    local name=""
    local platform="android"
    local app_id=""
    local script_id=""
    local devices=""
    local wait_completion=false
    local timeout=$DEFAULT_TIMEOUT
    local output_format=$DEFAULT_OUTPUT_FORMAT
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                name="$2"
                shift 2
                ;;
            --platform)
                platform="$2"
                shift 2
                ;;
            --app-id)
                app_id="$2"
                shift 2
                ;;
            --script-id)
                script_id="$2"
                shift 2
                ;;
            --devices)
                devices="$2"
                shift 2
                ;;
            --wait-completion)
                wait_completion=true
                shift
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --output)
                output_format="$2"
                shift 2
                ;;
            *)
                error_exit "未知参数: $1"
                ;;
        esac
    done
    
    # 验证必需参数
    [[ -z "$name" ]] && error_exit "缺少参数: --name"
    [[ -z "$app_id" ]] && error_exit "缺少参数: --app-id"
    [[ -z "$script_id" ]] && error_exit "缺少参数: --script-id"
    [[ -z "$devices" ]] && error_exit "缺少参数: --devices"
    
    # 构建请求数据
    local request_data
    request_data=$(jq -n \
        --arg name "$name" \
        --arg platform "$platform" \
        --arg app_id "$app_id" \
        --arg script_id "$script_id" \
        --arg devices "$devices" \
        '{
            name: $name,
            platform: $platform,
            app_id: ($app_id | tonumber),
            script_id: ($script_id | tonumber),
            devices: $devices
        }')
    
    log INFO "创建测试套件: $name"
    
    # 发送创建请求
    local response
    response=$(api_request POST "/api/v1/testsuites" "$request_data")
    
    local suite_id
    suite_id=$(echo "$response" | jq -r '.data.id')
    
    log SUCCESS "测试套件创建成功，ID: $suite_id"
    
    # 是否等待完成
    if [[ "$wait_completion" == true ]]; then
        response=$(wait_for_completion "$suite_id" "$timeout")
    fi
    
    # 输出结果
    if [[ "$output_format" == "json" ]]; then
        echo "$response" | jq '.'
    else
        echo "$suite_id"
    fi
}

# 查看测试套件状态
get_testsuite_status() {
    local suite_id=$1
    local output_format=${2:-$DEFAULT_OUTPUT_FORMAT}
    
    log INFO "查询测试套件状态: $suite_id"
    
    local response
    response=$(api_request GET "/api/v1/testsuites/$suite_id")
    
    if [[ "$output_format" == "json" ]]; then
        echo "$response" | jq '.'
    else
        local status
        status=$(echo "$response" | jq -r '.data.status')
        echo "$status"
    fi
}

# 列出测试套件
list_testsuites() {
    local status=""
    local limit=20
    local output_format=$DEFAULT_OUTPUT_FORMAT
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status)
                status="$2"
                shift 2
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            --output)
                output_format="$2"
                shift 2
                ;;
            *)
                error_exit "未知参数: $1"
                ;;
        esac
    done
    
    local endpoint="/api/v1/testsuites?limit=$limit"
    if [[ -n "$status" ]]; then
        endpoint="$endpoint&status=$status"
    fi
    
    log INFO "获取测试套件列表"
    
    local response
    response=$(api_request GET "$endpoint")
    
    if [[ "$output_format" == "json" ]]; then
        echo "$response" | jq '.'
    else
        echo "$response" | jq -r '.data[] | "\(.id)\t\(.name)\t\(.status)\t\(.created_at)"'
    fi
}

# 下载测试报告
download_report() {
    local suite_id=""
    local format="junit"
    local output_dir="./reports"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --id)
                suite_id="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --output)
                output_dir="$2"
                shift 2
                ;;
            *)
                error_exit "未知参数: $1"
                ;;
        esac
    done
    
    [[ -z "$suite_id" ]] && error_exit "缺少参数: --id"
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    log INFO "下载测试报告: $suite_id"
    
    # 获取报告下载链接
    local response
    response=$(api_request GET "/api/v1/testsuites/$suite_id/reports?format=$format")
    
    local download_url
    download_url=$(echo "$response" | jq -r '.data.download_url')
    
    if [[ "$download_url" == "null" || -z "$download_url" ]]; then
        error_exit "无法获取报告下载链接"
    fi
    
    # 下载报告文件
    local filename="${suite_id}_${format}_$(date +%Y%m%d_%H%M%S).zip"
    local filepath="$output_dir/$filename"
    
    if curl -L -o "$filepath" "$download_url"; then
        log SUCCESS "报告下载成功: $filepath"
        
        # 解压报告文件
        if command -v unzip &> /dev/null; then
            local extract_dir="$output_dir/${suite_id}_${format}"
            mkdir -p "$extract_dir"
            if unzip -q "$filepath" -d "$extract_dir"; then
                log SUCCESS "报告解压成功: $extract_dir"
            fi
        fi
    else
        error_exit "报告下载失败"
    fi
}

# 监控测试进度
watch_testsuite() {
    local suite_id=$1
    local interval=${2:-10}
    
    log INFO "监控测试套件进度: $suite_id"
    
    while true; do
        local response
        response=$(api_request GET "/api/v1/testsuites/$suite_id")
        
        local status
        status=$(echo "$response" | jq -r '.data.status')
        
        local progress
        progress=$(echo "$response" | jq -r '.data.progress // "0"')
        
        local timestamp
        timestamp=$(date '+%H:%M:%S')
        
        printf "\r[$timestamp] 状态: %-10s 进度: %s%%" "$status" "$progress"
        
        case $status in
            "completed"|"success"|"failed"|"error")
                printf "\n"
                log SUCCESS "测试套件执行完成，最终状态: $status"
                break
                ;;
        esac
        
        sleep "$interval"
    done
}

# =============================================================================
# 便捷脚本函数
# =============================================================================

# 快速冒烟测试
quick_smoke_test() {
    local app_id=$1
    local script_id=$2
    local name="Quick-Smoke-Test-$(date +%Y%m%d_%H%M%S)"
    
    create_testsuite \
        --name "$name" \
        --platform android \
        --app-id "$app_id" \
        --script-id "$script_id" \
        --devices "group:smoke-test" \
        --wait-completion \
        --timeout 600
}

# 完整回归测试
full_regression_test() {
    local app_id=$1
    local script_id=$2
    local name="Regression-Test-$(date +%Y%m%d_%H%M%S)"
    
    create_testsuite \
        --name "$name" \
        --platform android \
        --app-id "$app_id" \
        --script-id "$script_id" \
        --devices "group:full-test" \
        --wait-completion \
        --timeout 3600
}

# CI/CD集成脚本
ci_test_runner() {
    local config_file=${1:-".highqa.yml"}
    
    if [[ ! -f "$config_file" ]]; then
        error_exit "配置文件不存在: $config_file"
    fi
    
    log INFO "使用配置文件: $config_file"
    
    # 读取配置 (这里简化处理，实际项目中建议使用yq)
    local app_id
    app_id=$(grep "app_id:" "$config_file" | cut -d':' -f2 | tr -d ' ')
    
    local script_id
    script_id=$(grep "script_id:" "$config_file" | cut -d':' -f2 | tr -d ' ')
    
    local test_name="${CI_COMMIT_BRANCH:-manual}-${CI_PIPELINE_ID:-$(date +%s)}"
    
    create_testsuite \
        --name "$test_name" \
        --platform android \
        --app-id "$app_id" \
        --script-id "$script_id" \
        --devices "group:ci-test" \
        --wait-completion \
        --timeout 1800
}

# =============================================================================
# 帮助函数
# =============================================================================

show_help() {
    cat << EOF
HighQA CLI Tool - 移动端自动化测试平台命令行工具

用法:
    $0 <command> [options]

命令:
    auth <token>                    - 设置认证token
    create [options]                - 创建测试套件
    status <suite_id>               - 查看测试套件状态
    list [options]                  - 列出测试套件
    download [options]              - 下载测试报告
    watch <suite_id> [interval]     - 监控测试进度

    # 便捷命令
    smoke <app_id> <script_id>      - 快速冒烟测试
    regression <app_id> <script_id> - 完整回归测试
    ci-run [config_file]            - CI/CD环境运行

创建测试套件选项:
    --name <name>                   - 测试套件名称 (必需)
    --platform <platform>          - 平台 (android/ios, 默认: android)
    --app-id <id>                   - 应用ID (必需)
    --script-id <id>                - 脚本ID (必需)
    --devices <devices>             - 设备选择 (必需)
    --wait-completion               - 等待测试完成
    --timeout <seconds>             - 超时时间 (默认: 1800)
    --output <format>               - 输出格式 (json/text, 默认: json)

环境变量:
    HIGHQA_TOKEN                    - API认证令牌 (必需)
    HIGHQA_API_URL                  - API服务地址 (可选)
    LOG_LEVEL                       - 日志级别 (DEBUG/INFO, 默认: INFO)

示例:
    # 认证
    $0 auth your_api_token_here

    # 创建测试套件并等待完成
    $0 create --name "CI-Test" --app-id 12345 --script-id 67890 --devices "group:smoke-test" --wait-completion

    # 查看状态
    $0 status 123

    # 下载报告
    $0 download --id 123 --format junit --output ./reports

    # 快速冒烟测试
    $0 smoke 12345 67890

EOF
}

show_version() {
    echo "HighQA CLI Tool v1.0.0"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    # 检查基本依赖
    check_dependencies
    
    # 处理命令行参数
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    local command=$1
    shift
    
    case $command in
        auth)
            [[ $# -eq 0 ]] && error_exit "缺少token参数"
            auth_login "$1"
            ;;
        create)
            check_config
            create_testsuite "$@"
            ;;
        status)
            [[ $# -eq 0 ]] && error_exit "缺少suite_id参数"
            check_config
            get_testsuite_status "$@"
            ;;
        list)
            check_config
            list_testsuites "$@"
            ;;
        download)
            check_config
            download_report "$@"
            ;;
        watch)
            [[ $# -eq 0 ]] && error_exit "缺少suite_id参数"
            check_config
            watch_testsuite "$@"
            ;;
        smoke)
            [[ $# -lt 2 ]] && error_exit "参数不足: smoke <app_id> <script_id>"
            check_config
            quick_smoke_test "$1" "$2"
            ;;
        regression)
            [[ $# -lt 2 ]] && error_exit "参数不足: regression <app_id> <script_id>"
            check_config
            full_regression_test "$1" "$2"
            ;;
        ci-run)
            check_config
            ci_test_runner "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            error_exit "未知命令: $command"
            ;;
    esac
}

# 运行主函数
main "$@" 