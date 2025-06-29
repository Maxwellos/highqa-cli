# 🚀 GitHub 部署指南

将 HighQA CLI 发布到 GitHub 的完整指南。

## 快速部署

### 1. 创建GitHub仓库

```bash
# 在GitHub上创建新仓库: highqa-cli
# 选择Public，不初始化任何文件
```

### 2. 上传代码

```bash
cd highqa-cli
git init
git remote add origin https://github.com/YOUR_USERNAME/highqa-cli.git

# 更新仓库链接
sed -i 's/your-org\/highqa-cli/YOUR_USERNAME\/highqa-cli/g' README.md install.sh

git add .
git commit -m "🎉 Initial release: HighQA CLI v1.0.0"
git branch -M main
git push -u origin main
```

### 3. 创建Release

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## 🔗 重要文件说明

| 文件 | 用途 | 说明 |
|------|------|------|
| `highqa-cli.sh` | 主CLI工具 | 核心功能脚本 |
| `install.sh` | 一键安装 | 从GitHub自动下载安装 |
| `README.md` | 项目说明 | GitHub首页展示 |
| `test.sh` | 测试脚本 | 验证功能正常 |
| `build.sh` | 构建脚本 | 创建发布包 |
| `.github/workflows/ci.yml` | CI/CD | 自动测试和发布 |

## 📋 发布清单

- [ ] 创建GitHub仓库
- [ ] 上传所有文件
- [ ] 更新仓库链接
- [ ] 创建第一个tag
- [ ] 验证CI/CD运行
- [ ] 测试安装命令

## 🎯 用户使用方式

发布后，用户可以通过以下方式使用：

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/highqa-cli/main/install.sh | bash

# 手动下载
wget https://github.com/YOUR_USERNAME/highqa-cli/releases/latest/download/highqa-cli.sh
chmod +x highqa-cli.sh
```

## 📊 维护建议

1. **定期更新**: 修复bug，添加新功能
2. **用户反馈**: 通过Issues收集反馈
3. **文档维护**: 保持README和文档最新
4. **版本管理**: 遵循语义化版本规则

完成部署后，您的CLI工具就可以供全世界的开发者使用了！🌍 