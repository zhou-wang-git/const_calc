# 数易赋能 (ShuYi FuNeng)

数字测算与姓名测算的 Flutter 应用。

## 📱 iOS 发布

这是专门用于 iOS App Store 发布的仓库。

**详细配置说明请查看：[IOS_DEPLOYMENT.md](./IOS_DEPLOYMENT.md)**

## 🚀 自动化构建

本项目已配置自动化 CI/CD 流程：

- **Codemagic**（推荐）：`codemagic.yaml`
- **GitHub Actions**（备用）：`.github/workflows/ios-release.yml`

推送代码到 `master` 分支即可自动触发构建和发布到 TestFlight。

## 📦 应用信息

- **Bundle ID**: `app.numforlife.com`
- **当前版本**: 1.1.0 (121)
- **最低 iOS 版本**: 12.0
- **Flutter 版本**: 3.8.1+

## 🛠️ 开发

### 安装依赖
```bash
flutter pub get
```

### 运行应用
```bash
flutter run
```

### 构建 iOS
```bash
flutter build ios --release
```

## 📄 文档

- [iOS 部署完整指南](./IOS_DEPLOYMENT.md) - 包含证书配置、CI/CD 设置等详细步骤

## 🔒 注意事项

- 本仓库仅包含 Flutter 应用代码
- 后端代码在独立仓库
- 证书和密钥请通过 CI/CD 平台配置，不要提交到仓库
