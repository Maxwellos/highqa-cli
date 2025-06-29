#!/bin/bash

# HighQA CLI 一键安装脚本
# 从GitHub仓库自动下载并安装CLI工具

set -e

# 配置
GITHUB_REPO="Maxwellos/highqa-cli"
GITHUB_RAW_URL="https://raw.githubusercontent.com/$GITHUB_REPO/master"
INSTALL_DIR="$HOME/.highqa"
CLI_SCRIPT_URL="$GITHUB_RAW_URL/highqa-cli.sh"

# 颜色配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        else
            OS="linux"
        fi
    else
        error "不支持的操作系统: $OSTYPE"
    fi
    log "检测到操作系统: $OS"
}

# 检查依赖是否已安装
check_dependency() {
    local dep=$1
    if command -v "$dep" &> /dev/null; then
        success "$dep 已安装"
        return 0
    else
        warn "$dep 未安装"
        return 1
    fi
}

# 安装依赖
install_dependencies() {
    log "检查并安装依赖..."
    
    case $OS in
        macos)
            # 检查是否安装了 Homebrew
            if ! command -v brew &> /dev/null; then
                log "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # 安装依赖
            if ! check_dependency curl; then
                log "安装 curl..."
                brew install curl
            fi
            
            if ! check_dependency jq; then
                log "安装 jq..."
                brew install jq
            fi
            ;;
            
        ubuntu)
            # 更新包列表
            log "更新软件包列表..."
            sudo apt-get update -qq
            
            # 安装依赖
            if ! check_dependency curl; then
                log "安装 curl..."
                sudo apt-get install -y curl
            fi
            
            if ! check_dependency jq; then
                log "安装 jq..."
                sudo apt-get install -y jq
            fi
            ;;
            
        centos)
            # 安装 EPEL 仓库（如果需要）
            if ! rpm -q epel-release &> /dev/null; then
                log "安装 EPEL 仓库..."
                sudo yum install -y epel-release
            fi
            
            # 安装依赖
            if ! check_dependency curl; then
                log "安装 curl..."
                sudo yum install -y curl
            fi
            
            if ! check_dependency jq; then
                log "安装 jq..."
                sudo yum install -y jq
            fi
            ;;
            
        *)
            error "请手动安装 curl 和 jq"
            ;;
    esac
    
    success "所有依赖安装完成"
}

# 下载并安装CLI工具
install_cli() {
    log "从GitHub下载 HighQA CLI 工具..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 下载CLI脚本
    log "下载CLI脚本从: $CLI_SCRIPT_URL"
    if curl -fsSL "$CLI_SCRIPT_URL" -o "$INSTALL_DIR/highqa-cli.sh"; then
        chmod +x "$INSTALL_DIR/highqa-cli.sh"
        success "CLI脚本已安装到: $INSTALL_DIR/highqa-cli.sh"
    else
        error "下载CLI脚本失败"
    fi
    
    # 创建符号链接到 /usr/local/bin （如果有权限）
    if [[ -w "/usr/local/bin" ]]; then
        ln -sf "$INSTALL_DIR/highqa-cli.sh" "/usr/local/bin/highqa"
        success "已创建全局命令: highqa"
    elif sudo -n true 2>/dev/null; then
        # 如果有sudo权限，尝试使用sudo创建链接
        sudo ln -sf "$INSTALL_DIR/highqa-cli.sh" "/usr/local/bin/highqa"
        success "已创建全局命令: highqa (使用sudo)"
    else
        warn "无法创建全局命令，将添加到PATH"
    fi
}

# 配置环境
setup_environment() {
    log "配置环境..."
    
    local shell_rc=""
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    # 添加 PATH 配置（如果需要）
    if ! grep -q "\.highqa" "$shell_rc" 2>/dev/null; then
        echo '' >> "$shell_rc"
        echo '# HighQA CLI' >> "$shell_rc"
        echo 'export PATH="$HOME/.highqa:$PATH"' >> "$shell_rc"
        log "已添加 HighQA CLI 到 PATH ($shell_rc)"
    fi
    
    # 下载配置文件模板
    log "下载配置文件模板..."
    curl -fsSL "$GITHUB_RAW_URL/.highqa.yml" -o "$INSTALL_DIR/config.yml.example" || warn "配置文件模板下载失败"
    
    # 创建本地配置文件
    if [[ ! -f "$INSTALL_DIR/config" ]]; then
        cat > "$INSTALL_DIR/config" << 'EOF'
# HighQA CLI 配置文件
# 设置默认的API地址和其他选项

# API配置
export HIGHQA_API_URL="https://api.highqa.com"
# export HIGHQA_TOKEN="your_token_here"  # 取消注释并设置您的token

# 日志级别
export LOG_LEVEL="INFO"

# 默认超时时间（秒）
export HIGHQA_DEFAULT_TIMEOUT="1800"
EOF
        log "已创建配置文件: $INSTALL_DIR/config"
    fi
}

# 验证安装
verify_installation() {
    log "验证安装..."
    
    # 检查CLI工具是否可用
    if command -v highqa &> /dev/null; then
        success "highqa 命令可用"
        highqa version
    elif [[ -x "$INSTALL_DIR/highqa-cli.sh" ]]; then
        success "CLI工具已安装"
        "$INSTALL_DIR/highqa-cli.sh" version
    else
        error "安装验证失败"
    fi
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo "🎉 HighQA CLI 安装完成！"
    echo ""
    echo "📋 后续步骤："
    echo ""
    echo "1. 重新加载shell配置或重启终端："
    echo "   source ~/.bashrc  # 或 source ~/.zshrc"
    echo ""
    echo "2. 设置API令牌："
    echo "   export HIGHQA_TOKEN=\"your_api_token_here\""
    echo ""
    echo "3. 验证连接："
    echo "   highqa auth \$HIGHQA_TOKEN"
    echo ""
    echo "4. 创建测试套件："
    echo "   highqa create --name \"我的测试\" --app-id 123 --script-id 456 --devices \"group:test\""
    echo ""
    echo "📚 查看在线文档："
    echo "   https://github.com/$GITHUB_REPO"
    echo ""
    echo "🔧 配置文件位置："
    echo "   $INSTALL_DIR/config"
    echo "   $INSTALL_DIR/config.yml.example"
    echo ""
    echo "📝 示例配置文件："
    echo "   cp $INSTALL_DIR/config.yml.example .highqa.yml"
    echo ""
}

# 主函数
main() {
    echo "🚀 HighQA CLI 一键安装程序"
    echo "从GitHub仓库: $GITHUB_REPO"
    echo ""
    
    # 检测操作系统
    detect_os
    
    # 安装依赖
    install_dependencies
    
    # 安装CLI工具
    install_cli
    
    # 配置环境
    setup_environment
    
    # 验证安装
    verify_installation
    
    # 显示后续步骤
    show_next_steps
}

# 运行主函数
main "$@" 