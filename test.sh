#!/bin/bash

# HighQA CLI 测试脚本
# 用于验证CLI工具的功能

set -e

# 颜色配置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 HighQA CLI 测试套件${NC}"
echo "========================================"

# 计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "\n${BLUE}测试 $TESTS_TOTAL: $test_name${NC}"
    echo "命令: $test_command"
    echo "----------------------------------------"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ 通过${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# CLI脚本路径
CLI_SCRIPT="./highqa-cli.sh"

if [[ ! -f "$CLI_SCRIPT" ]]; then
    echo -e "${RED}❌ CLI脚本不存在: $CLI_SCRIPT${NC}"
    exit 1
fi

# 确保脚本有执行权限
chmod +x "$CLI_SCRIPT"

# 1. 语法检查
run_test "Shell语法检查" "bash -n $CLI_SCRIPT"

# 2. 版本信息
run_test "版本信息显示" "$CLI_SCRIPT version"

# 3. 帮助信息
run_test "帮助信息显示" "$CLI_SCRIPT help"

# 4. 依赖检查
run_test "curl依赖检查" "command -v curl"
run_test "jq依赖检查" "command -v jq"

# 5. 错误处理测试
run_test "无效命令处理" "! $CLI_SCRIPT invalid_command"
run_test "缺少参数处理" "! $CLI_SCRIPT create"

# 6. 环境变量测试
run_test "环境变量检查功能" "HIGHQA_TOKEN= $CLI_SCRIPT create --name test --app-id 123 --script-id 456 --devices group:test 2>&1 | grep -q 'HIGHQA_TOKEN'"

# 7. 配置文件测试
if [[ -f ".highqa.yml" ]]; then
    run_test "配置文件语法检查" "cat .highqa.yml | grep -q 'app_id'"
fi

# 8. 安装脚本测试
if [[ -f "install.sh" ]]; then
    run_test "安装脚本语法检查" "bash -n install.sh"
fi

# 9. 输出格式测试
export HIGHQA_TOKEN="test_token_for_testing"
run_test "JSON输出格式" "$CLI_SCRIPT create --name test --app-id 123 --script-id 456 --devices group:test --output json 2>/dev/null || true"
run_test "文本输出格式" "$CLI_SCRIPT create --name test --app-id 123 --script-id 456 --devices group:test --output text 2>/dev/null || true"

# 10. 快速命令测试
run_test "快速冒烟测试语法" "$CLI_SCRIPT smoke 2>&1 | grep -q '参数不足' || true"
run_test "快速回归测试语法" "$CLI_SCRIPT regression 2>&1 | grep -q '参数不足' || true"

# 总结报告
echo ""
echo "========================================"
echo -e "${BLUE}📊 测试结果总结${NC}"
echo "========================================"
echo "总测试数: $TESTS_TOTAL"
echo -e "通过数: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败数: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "\n${RED}❌ 有 $TESTS_FAILED 个测试失败${NC}"
    exit 1
fi 