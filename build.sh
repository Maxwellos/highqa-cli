#!/bin/bash

# HighQA CLI 构建打包脚本
# 用于创建发布包

set -e

# 颜色配置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 配置
BUILD_DIR="dist"
VERSION=$(grep "HighQA CLI Tool v" highqa-cli.sh | head -1 | sed 's/.*v\([0-9.]*\).*/\1/')
PACKAGE_NAME="highqa-cli-v${VERSION}"

echo -e "${BLUE}📦 HighQA CLI 构建脚本${NC}"
echo "========================================"
echo "版本: $VERSION"
echo "构建目录: $BUILD_DIR"
echo "包名: $PACKAGE_NAME"
echo ""

# 清理并创建构建目录
echo -e "${BLUE}🧹 清理构建目录...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 运行测试
echo -e "${BLUE}🧪 运行测试...${NC}"
if [[ -f "test.sh" ]]; then
    chmod +x test.sh
    ./test.sh
    echo -e "${GREEN}✅ 测试通过${NC}"
else
    echo -e "${YELLOW}⚠️  未找到测试脚本，跳过测试${NC}"
fi

# 复制文件到构建目录
echo -e "${BLUE}📋 复制文件...${NC}"
cp highqa-cli.sh "$BUILD_DIR/"
cp install.sh "$BUILD_DIR/"
cp README.md "$BUILD_DIR/"
cp LICENSE "$BUILD_DIR/"
cp CHANGELOG.md "$BUILD_DIR/"
cp .highqa.yml "$BUILD_DIR/"

# 创建版本信息文件
echo -e "${BLUE}📝 创建版本信息...${NC}"
cat > "$BUILD_DIR/VERSION" << EOF
HighQA CLI v$VERSION
Build Date: $(date '+%Y-%m-%d %H:%M:%S')
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
Platform: $(uname -s)-$(uname -m)
EOF

# 创建安装说明
echo -e "${BLUE}📖 创建安装说明...${NC}"
cat > "$BUILD_DIR/INSTALL.txt" << EOF
HighQA CLI v$VERSION 安装说明
===============================

一键安装（推荐）:
curl -fsSL https://raw.githubusercontent.com/your-org/highqa-cli/main/install.sh | bash

手动安装:
1. 将 highqa-cli.sh 复制到您的系统路径
2. 赋予执行权限: chmod +x highqa-cli.sh
3. 安装依赖: curl, jq
4. 设置环境变量: export HIGHQA_TOKEN="your_token"

验证安装:
./highqa-cli.sh version

更多信息请查看 README.md
EOF

# 创建快速开始脚本
echo -e "${BLUE}⚡ 创建快速开始脚本...${NC}"
cat > "$BUILD_DIR/quickstart.sh" << 'EOF'
#!/bin/bash

# HighQA CLI 快速开始脚本

set -e

echo "🚀 HighQA CLI 快速开始"
echo "======================"

# 检查环境
if ! command -v curl &> /dev/null; then
    echo "❌ curl 未安装，请先安装 curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq 未安装，请先安装 jq"
    exit 1
fi

if [[ -z "${HIGHQA_TOKEN:-}" ]]; then
    echo "❌ 请设置 HIGHQA_TOKEN 环境变量"
    echo "   export HIGHQA_TOKEN=\"your_api_token_here\""
    exit 1
fi

# 设置执行权限
chmod +x highqa-cli.sh

# 验证安装
echo "验证CLI工具..."
./highqa-cli.sh version

# 测试认证
echo "测试认证..."
./highqa-cli.sh auth $HIGHQA_TOKEN

echo "✅ 快速开始完成！"
echo ""
echo "下一步："
echo "1. 创建测试套件："
echo "   ./highqa-cli.sh create --name \"我的测试\" --app-id 123 --script-id 456 --devices \"group:test\""
echo ""
echo "2. 查看帮助："
echo "   ./highqa-cli.sh help"
EOF

chmod +x "$BUILD_DIR/quickstart.sh"

# 验证构建的文件
echo -e "${BLUE}🔍 验证构建文件...${NC}"
for file in highqa-cli.sh install.sh README.md LICENSE; do
    if [[ -f "$BUILD_DIR/$file" ]]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file 缺失${NC}"
        exit 1
    fi
done

# 测试构建的CLI脚本
echo -e "${BLUE}🧪 测试构建的CLI脚本...${NC}"
cd "$BUILD_DIR"
chmod +x highqa-cli.sh
if ./highqa-cli.sh version | grep -q "$VERSION"; then
    echo -e "${GREEN}✅ CLI脚本版本正确${NC}"
else
    echo -e "${RED}❌ CLI脚本版本不匹配${NC}"
    exit 1
fi
cd ..

# 创建压缩包
echo -e "${BLUE}📦 创建压缩包...${NC}"
cd "$BUILD_DIR"
tar -czf "../${PACKAGE_NAME}.tar.gz" .
zip -r "../${PACKAGE_NAME}.zip" . >/dev/null
cd ..

# 计算校验和
echo -e "${BLUE}🔐 计算校验和...${NC}"
if command -v sha256sum &> /dev/null; then
    sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
    sha256sum "${PACKAGE_NAME}.zip" > "${PACKAGE_NAME}.zip.sha256"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
    shasum -a 256 "${PACKAGE_NAME}.zip" > "${PACKAGE_NAME}.zip.sha256"
fi

# 显示构建结果
echo ""
echo -e "${GREEN}🎉 构建完成！${NC}"
echo "========================================"
echo "构建文件:"
ls -la "$BUILD_DIR"
echo ""
echo "发布包:"
ls -la "${PACKAGE_NAME}".* 2>/dev/null || true
echo ""
echo "下一步:"
echo "1. 测试发布包: tar -xzf ${PACKAGE_NAME}.tar.gz && cd dist && ./quickstart.sh"
echo "2. 创建GitHub Release"
echo "3. 上传发布包到GitHub Releases"
echo ""
echo -e "${BLUE}📋 发布清单:${NC}"
echo "- [ ] 更新 CHANGELOG.md"
echo "- [ ] 更新版本号"
echo "- [ ] 运行测试"
echo "- [ ] 创建 Git tag"
echo "- [ ] 推送到 GitHub"
echo "- [ ] 创建 Release"
echo "- [ ] 通知用户" 