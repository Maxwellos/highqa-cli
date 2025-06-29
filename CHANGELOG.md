# 更新日志

本项目的所有重要更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/spec/v2.0.0.html)。

## [未发布]

### 计划中
- 支持更多输出格式
- 增加批量操作功能
- 添加测试套件模板
- 支持配置文件验证

## [1.0.0] - 2024-01-XX

### 新增
- ✨ 初始发布版本
- 🔐 API Token 认证系统
- 📱 多平台支持 (Android, iOS, HarmonyOS)
- 🧪 测试套件管理功能
  - 创建测试套件
  - 查看测试状态
  - 监控测试进度
  - 列出测试套件
- 📊 测试报告下载
  - 支持 JUnit 格式
  - 支持 HTML 格式
  - 支持 JSON 格式
  - 自动解压功能
- ⚡ 快速命令
  - 冒烟测试 (`smoke`)
  - 回归测试 (`regression`)
  - CI/CD 运行 (`ci-run`)
- 🔄 CI/CD 集成支持
  - GitLab CI/CD
  - GitHub Actions
  - Jenkins Pipeline
- 📁 配置文件管理
  - YAML 配置支持
  - 环境变量配置
  - 配置文件模板
- 🛠️ 工具功能
  - 彩色日志输出
  - 错误处理和重试
  - 详细的帮助信息
  - 版本信息显示
- 📦 安装支持
  - 一键安装脚本
  - 多操作系统支持
  - 依赖自动检查
  - 环境配置

### 支持的平台
- macOS (通过 Homebrew)
- Ubuntu/Debian (通过 apt)
- CentOS/RHEL (通过 yum)

### 支持的CI/CD平台
- GitLab CI/CD
- GitHub Actions
- Jenkins
- 其他支持 shell 脚本的平台

### 技术规格
- Shell: Bash 4.0+
- 依赖: curl, jq
- 最小系统要求: Linux/macOS/WSL

---

## 版本说明

### 语义化版本规则
- **主版本号 (MAJOR)**: 不兼容的API更改
- **次版本号 (MINOR)**: 向后兼容的功能性新增
- **修订号 (PATCH)**: 向后兼容的问题修正

### 更新日志格式
- `新增` - 新功能
- `更改` - 对现有功能的更改
- `弃用` - 即将移除的功能
- `移除` - 已移除的功能
- `修复` - 任何问题修复
- `安全` - 安全性相关的修复 