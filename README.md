# HighQA CLI

🚀 移动端自动化测试平台的官方命令行工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg)](#installation)

## 📋 简介

HighQA CLI 是一个强大的命令行工具，用于与 HighQA 移动端自动化测试平台进行交互。支持测试套件创建、执行监控、报告下载等功能，完美适配 CI/CD 环境。

### ✨ 主要功能

- 🔐 **安全认证** - 支持 API Token 认证
- 📱 **多平台支持** - Android、iOS、HarmonyOS
- 🧪 **测试管理** - 创建、监控、管理测试套件
- 📊 **报告下载** - 支持多种格式（JUnit、HTML、JSON）
- 🔄 **CI/CD 集成** - 完美适配 GitLab、GitHub、Jenkins
- ⚡ **快速命令** - 内置冒烟测试、回归测试模板
- 📁 **配置管理** - 支持配置文件简化操作

## 🚀 快速开始

### 一键安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/Maxwellos/highqa-cli/master/install.sh | bash

# 或者手动安装
git clone https://github.com/Maxwellos/highqa-cli.git
cd highqa-cli
chmod +x install.sh
./install.sh
```

### 手动安装

```bash
# 1. 下载CLI脚本
wget https://raw.githubusercontent.com/Maxwellos/highqa-cli/master/highqa-cli.sh
chmod +x highqa-cli.sh

# 2. 安装依赖
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq

# 3. 设置环境变量
export HIGHQA_TOKEN="your_api_token_here"

# 4. 验证安装
./highqa-cli.sh version
```

## 📖 使用指南

### 基础用法

```bash
# 认证
highqa auth your_token_here

# 创建测试套件
highqa create \
  --name "我的测试套件" \
  --app-id 12345 \
  --script-id 67890 \
  --devices "group:smoke-test"

# 查看状态
highqa status 123

# 下载报告
highqa download --id 123 --format junit
```

### 快速命令

```bash
# 快速冒烟测试（10分钟）
highqa smoke 12345 67890

# 完整回归测试（60分钟）
highqa regression 12345 67891

# CI/CD环境运行
highqa ci-run .highqa.yml
```

### 配置文件

创建 `.highqa.yml` 配置文件：

```yaml
# 应用配置
app_id: 12345
script_id: 67890

# 默认设置
platform: android
devices: group:ci-test
timeout: 1800
```

## 🔄 CI/CD 集成

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - test

mobile_test:
  stage: test
  before_script:
    - curl -fsSL https://raw.githubusercontent.com/Maxwellos/highqa-cli/master/install.sh | bash
  script:
    - highqa ci-run .highqa.yml
  artifacts:
    reports:
      junit: test-reports/junit.xml
  only:
    - merge_requests
    - main
```

### GitHub Actions

```yaml
# .github/workflows/mobile-test.yml
name: Mobile Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install HighQA CLI
        run: curl -fsSL https://raw.githubusercontent.com/Maxwellos/highqa-cli/master/install.sh | bash
      
      - name: Run Tests
        env:
          HIGHQA_TOKEN: ${{ secrets.HIGHQA_TOKEN }}
        run: highqa ci-run .highqa.yml
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    environment {
        HIGHQA_TOKEN = credentials('highqa-api-token')
    }
    stages {
        stage('Setup') {
            steps {
                sh 'curl -fsSL https://raw.githubusercontent.com/Maxwellos/highqa-cli/master/install.sh | bash'
            }
        }
        stage('Test') {
            steps {
                sh 'highqa ci-run .highqa.yml'
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-reports/junit.xml'
                }
            }
        }
    }
}
```

## 📚 完整文档

- [安装指南](docs/installation.md)
- [使用教程](docs/usage.md)
- [CI/CD集成](docs/ci-cd.md)
- [API参考](docs/api.md)
- [故障排除](docs/troubleshooting.md)

## 🛠️ 开发

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/Maxwellos/highqa-cli.git
cd highqa-cli

# 运行测试
./test-cli.sh

# 构建发布包
./build.sh
```

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📋 命令参考

### 主要命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `auth` | 设置认证token | `highqa auth <token>` |
| `create` | 创建测试套件 | `highqa create --name "测试" --app-id 123` |
| `status` | 查看测试状态 | `highqa status 123` |
| `list` | 列出测试套件 | `highqa list --status running` |
| `download` | 下载测试报告 | `highqa download --id 123 --format junit` |
| `watch` | 监控测试进度 | `highqa watch 123` |
| `smoke` | 快速冒烟测试 | `highqa smoke 12345 67890` |
| `regression` | 完整回归测试 | `highqa regression 12345 67891` |

### 环境变量

| 变量 | 描述 | 必需 |
|------|------|------|
| `HIGHQA_TOKEN` | API认证令牌 | ✅ |
| `HIGHQA_API_URL` | API服务地址 | ❌ |
| `LOG_LEVEL` | 日志级别 (DEBUG/INFO) | ❌ |

## 🔍 故障排除

### 常见问题

**认证失败**
```bash
# 检查token
echo $HIGHQA_TOKEN

# 验证连接
curl -H "Authorization: Bearer $HIGHQA_TOKEN" "$HIGHQA_API_URL/api/v1/auth/verify"
```

**依赖缺失**
```bash
# macOS
brew install curl jq

# Ubuntu
sudo apt-get install curl jq
```

**权限问题**
```bash
# 检查脚本权限
chmod +x highqa-cli.sh

# 检查目录权限
ls -la ~/.highqa/
```

## 📊 版本历史

- **v1.0.0** - 初始版本
  - 基础CLI功能
  - CI/CD集成支持
  - 多平台支持

## 🤝 支持

- 📖 [文档](https://docs.highqa.com)
- 🐛 [Issues](https://github.com/Maxwellos/highqa-cli/issues)
- 💬 [讨论](https://github.com/Maxwellos/highqa-cli/discussions)
- 📧 [邮件支持](mailto:support@highqa.com)

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有为此项目做出贡献的开发者！

---

<p align="center">
  Made with ❤️ by the HighQA Team
</p> 