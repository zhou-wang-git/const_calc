# iOS 自动化部署配置指南

本文档详细说明如何使用 CI/CD 自动构建并发布 iOS 应用到 App Store。

---

## 📋 前置准备清单

### 1. Apple Developer 账号要求
- ✅ Apple Developer Program 会员资格（$99/年）
- ✅ App Store Connect 访问权限
- ✅ 已创建 App ID：`app.numforlife.com`

### 2. 必需的证书和文件
需要在 Apple Developer 网站生成以下文件：

#### A. iOS Distribution Certificate (发布证书)
- 文件格式：`.p12`
- 用途：签名 iOS 应用

#### B. Provisioning Profile (配置文件)
- 类型：App Store Distribution
- 文件格式：`.mobileprovision`

#### C. App Store Connect API Key (推荐)
- 文件格式：`.p8`
- 包含：Key ID, Issuer ID, Private Key

---

## 🎯 方案选择

我为你准备了两套配置：

| 方案 | 推荐度 | 免费额度 | 配置难度 | 文件位置 |
|------|--------|----------|----------|----------|
| **Codemagic** | ⭐⭐⭐⭐⭐ | 500分钟/月 | 简单 | `codemagic.yaml` |
| **GitHub Actions** | ⭐⭐⭐⭐ | 200分钟/月 | 中等 | `.github/workflows/ios-release.yml` |

**建议使用 Codemagic**，专为 Flutter 设计，配置更简单。

---

## 🚀 方案一：Codemagic（推荐）

### 步骤 1：注册 Codemagic

1. 访问：https://codemagic.io/
2. 使用 GitHub 账号登录
3. 授权 Codemagic 访问你的 GitHub 仓库

### 步骤 2：连接 GitHub 仓库

1. 在 Codemagic 控制台点击 **"Add application"**
2. 选择你的 GitHub 仓库
3. Codemagic 会自动检测到 `codemagic.yaml` 文件

### 步骤 3：配置 App Store Connect 集成

1. 在 Codemagic 中进入 **Teams > Integrations**
2. 点击 **"Add integration" > "App Store Connect"**
3. 选择两种方式之一：

#### 方式 A：使用 App Store Connect API Key（推荐）

上传以下信息：
- **Issuer ID**：从 App Store Connect > 用户和访问 > 密钥 获取
- **Key ID**：API Key 的 ID
- **API Key file (.p8)**：下载的私钥文件

#### 方式 B：使用 Apple ID（较简单但不推荐）

输入：
- Apple ID（你的 iCloud 邮箱）
- App-specific password（应用专用密码）

生成应用专用密码：
1. 访问 https://appleid.apple.com/
2. 登录后进入"安全"部分
3. 生成应用专用密码

### 步骤 4：配置 iOS 证书

1. 在 Codemagic App 设置中，进入 **"Code signing identities"**
2. 点击 **"iOS code signing"**
3. 上传：
   - **Certificate (.p12)**：iOS Distribution Certificate
   - **Certificate password**：证书密码
   - **Provisioning profile (.mobileprovision)**：App Store 配置文件

### 步骤 5：修改 `codemagic.yaml`

打开 `codemagic.yaml`，替换以下占位符：

```yaml
PLACEHOLDER_APPLE_ID  →  你的 Apple ID (如果需要)
PLACEHOLDER_EMAIL     →  接收构建通知的邮箱
```

### 步骤 6：触发构建

1. 推送代码到 GitHub master 分支
2. Codemagic 会自动开始构建
3. 构建完成后自动上传到 TestFlight

### 步骤 7：在 App Store Connect 提交审核

1. 登录 https://appstoreconnect.apple.com/
2. 进入你的应用
3. 填写应用元数据（截图、描述等）
4. 提交审核

---

## 🔧 方案二：GitHub Actions（备用）

### 步骤 1：准备证书文件

在本地执行以下命令，将证书转换为 Base64：

```bash
# 转换证书
base64 -i your_certificate.p12 -o certificate_base64.txt

# 转换 Provisioning Profile
base64 -i your_profile.mobileprovision -o profile_base64.txt

# 转换 API Key（如果使用）
base64 -i AuthKey_XXXXXX.p8 -o api_key_base64.txt
```

### 步骤 2：配置 GitHub Secrets

在 GitHub 仓库中：
1. 进入 **Settings > Secrets and variables > Actions**
2. 点击 **"New repository secret"**
3. 添加以下 Secrets：

| Secret 名称 | 说明 | 来源 |
|------------|------|------|
| `IOS_CERTIFICATE_BASE64` | 证书 Base64 | certificate_base64.txt 内容 |
| `IOS_CERTIFICATE_PASSWORD` | 证书密码 | 创建证书时设置的密码 |
| `IOS_PROVISIONING_PROFILE_BASE64` | 配置文件 Base64 | profile_base64.txt 内容 |
| `KEYCHAIN_PASSWORD` | Keychain 密码 | 随机生成（如：`openssl rand -base64 32`） |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | App Store Connect 获取 |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID | App Store Connect 获取 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | API Key Base64 | api_key_base64.txt 内容 |

### 步骤 3：触发构建

推送代码到 GitHub，Actions 会自动运行。

---

## 📝 生成所需证书的详细步骤

### 1. 生成 iOS Distribution Certificate

1. 在 Mac 上打开 **Keychain Access**（钥匙串访问）
2. 菜单栏：**Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority**
3. 填写信息：
   - User Email Address：你的邮箱
   - Common Name：你的名字
   - Request is：**Saved to disk**
4. 保存 `CertificateSigningRequest.certSigningRequest` 文件

5. 访问 https://developer.apple.com/account/resources/certificates/list
6. 点击 **"+"** 创建新证书
7. 选择 **"Apple Distribution"**
8. 上传刚才保存的 `.certSigningRequest` 文件
9. 下载生成的 `distribution.cer` 证书

10. 双击 `distribution.cer` 导入到 Keychain
11. 在 Keychain 中找到证书，右键 **Export**
12. 导出为 `.p12` 格式，设置密码（请记住此密码）

### 2. 生成 Provisioning Profile

1. 访问 https://developer.apple.com/account/resources/profiles/list
2. 点击 **"+"** 创建新 Profile
3. 选择 **"App Store"** 类型
4. 选择你的 App ID：`app.numforlife.com`
5. 选择刚才创建的 Distribution Certificate
6. 下载 `.mobileprovision` 文件

### 3. 生成 App Store Connect API Key（可选但推荐）

1. 访问 https://appstoreconnect.apple.com/access/api
2. 点击 **"+"** 生成新密钥
3. 输入名称，选择权限 **"App Manager"**
4. 下载 `.p8` 文件（**只能下载一次，请妥善保存**）
5. 记录 **Key ID** 和 **Issuer ID**

---

## ⚠️ 如果没有 Mac 怎么生成证书？

### 临时方案：租用 MacinCloud

1. 访问 https://www.macincloud.com/
2. 选择 **"Pay As You Go"** 计划（$1/小时）
3. 租用 1-2 小时完成证书生成
4. 按照上面的步骤生成证书
5. 下载证书后断开连接

**预计成本：$2-4**

---

## 🔍 常见问题

### Q1：构建失败，提示 "Provisioning profile doesn't match"
**A**：检查 Bundle ID 是否匹配。确保：
- `pubspec.yaml` 中没有定义 Bundle ID
- `ios/Runner.xcodeproj/project.pbxproj` 中 Bundle ID 为 `app.numforlife.com`
- Provisioning Profile 的 App ID 为 `app.numforlife.com`

### Q2：上传到 App Store 失败
**A**：确认：
- App Store Connect 中已创建应用
- 版本号正确且未被使用
- 证书和 Profile 未过期

### Q3：TestFlight 收不到构建
**A**：
- 检查 Codemagic 构建日志
- 确认 `submit_to_testflight: true`
- 等待 Apple 处理（可能需要 10-30 分钟）

### Q4：Codemagic 免费额度用完了怎么办？
**A**：切换到 GitHub Actions，或升级 Codemagic 付费计划。

---

## 📞 需要我提供的信息

当你准备好后，请提供：

1. ✅ 新的 GitHub 仓库地址（你会创建）
2. ✅ 接收构建通知的邮箱
3. ✅ Apple ID（如果使用方式 B）
4. ⚠️ 证书文件（我会指导你如何上传到 Codemagic，不会直接给我）

---

## 🎉 完成

配置完成后，每次推送代码到 GitHub，都会自动：
1. 构建 iOS 应用
2. 上传到 TestFlight
3. 发送邮件通知

你只需在 App Store Connect 网页上完成最后的元数据填写和提交审核即可！

---

**创建日期**：2025-12-10
**作者**：Claude Code Assistant
