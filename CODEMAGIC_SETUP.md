# Codemagic 配置步骤 - 快速上手指南

你的代码已成功推送到：`https://github.com/zhou-wang-git/const_calc`

现在按照以下步骤配置 Codemagic 自动构建。

---

## 📋 配置概览

- **触发方式**: 只在推送 Tag（如 v1.1.0）时构建
- **构建结果**: 自动上传到 TestFlight
- **通知邮箱**: 184232456@qq.com

---

## 🚀 步骤 1：注册并连接 Codemagic

### 1.1 访问 Codemagic
打开浏览器访问：https://codemagic.io/

### 1.2 使用 GitHub 登录
1. 点击 **"Sign up for free"**
2. 选择 **"Continue with GitHub"**
3. 授权 Codemagic 访问你的 GitHub 账号
4. 如果 GitHub 提示选择仓库，选择 **"All repositories"** 或至少选择 `const_calc` 仓库

### 1.3 添加应用
1. 登录后，点击 **"Add application"**
2. 选择 **"GitHub"** 作为代码源
3. 在仓库列表中找到并选择 **`zhou-wang-git/const_calc`**
4. Codemagic 会自动检测到项目根目录的 `codemagic.yaml` 文件
5. 点击 **"Add application"**

---

## 🔐 步骤 2：配置 App Store Connect 集成

这一步是关键，用于自动上传应用到 TestFlight。

### 2.1 进入集成设置
1. 在 Codemagic 控制台，点击左侧 **"Teams"**
2. 选择你的团队（通常是你的用户名）
3. 点击 **"Integrations"** 标签
4. 点击 **"Add integration"** → 选择 **"App Store Connect"**

### 2.2 配置方式选择

你有两种方式，推荐使用**方式 A**：

---

### 方式 A：App Store Connect API Key（推荐）

#### 生成 API Key

1. 访问：https://appstoreconnect.apple.com/access/integrations/api
2. 登录你的 Apple Developer 账号
3. 点击 **"+"** 生成新密钥
4. 输入密钥名称（例如：`Codemagic CI`）
5. 选择权限：**"App Manager"**
6. 点击 **"Generate"**
7. **重要**：立即下载 `.p8` 文件（只能下载一次！）
8. 记录以下信息：
   - **Issuer ID**（页面顶部，格式：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx）
   - **Key ID**（生成的密钥 ID）

#### 在 Codemagic 中配置

返回 Codemagic：
1. 在 App Store Connect 集成页面
2. 输入 **Issuer ID**
3. 输入 **Key ID**
4. 上传 `.p8` 文件
5. 点击 **"Save"**

---

### 方式 B：Apple ID 账号（简单但不推荐）

如果暂时无法生成 API Key，可以临时使用：

1. 输入你的 **Apple ID**（iCloud 邮箱）
2. 输入 **App-specific password**（应用专用密码）

#### 生成应用专用密码：
1. 访问：https://appleid.apple.com/
2. 登录后，进入 **"安全"** 部分
3. 在 **"应用专用密码"** 下点击 **"生成密码"**
4. 输入标签（如：Codemagic）
5. 复制生成的密码
6. 在 Codemagic 中粘贴

---

## 📱 步骤 3：配置 iOS 签名证书

### 3.1 准备证书文件

⚠️ **重要**：你需要在 Mac 上生成以下文件（或租用 MacinCloud）：

1. **iOS Distribution Certificate** (`.p12` 文件)
2. **Provisioning Profile** (`.mobileprovision` 文件)

详细生成步骤请参考：`IOS_DEPLOYMENT.md` 文档中的"生成所需证书的详细步骤"部分。

### 3.2 在 Codemagic 中上传证书

1. 在 Codemagic 中，进入你的应用
2. 点击 **"Settings"** 标签
3. 找到 **"Code signing identities"** 部分
4. 点击 **"iOS code signing"**
5. 上传文件：
   - **Certificate (.p12)**：选择你的 `.p12` 证书文件
   - **Certificate password**：输入创建证书时设置的密码
   - **Provisioning profile (.mobileprovision)**：选择你的配置文件
6. 点击 **"Save"**

---

## ⚙️ 步骤 4：配置工作流

### 4.1 选择工作流

1. 进入应用主页
2. 点击 **"Start new build"** 或 **"Workflows"**
3. 你会看到 `ios-release` 工作流（已在 `codemagic.yaml` 中配置）
4. 点击该工作流进入设置

### 4.2 确认配置

检查以下配置是否正确：

| 配置项 | 预期值 | 说明 |
|--------|--------|------|
| **Triggering** | Tag: `v*` | 只在推送版本号 Tag 时触发 |
| **Bundle ID** | `app.numforlife.com` | 应用包标识符 |
| **Email** | `184232456@qq.com` | 通知邮箱 |
| **TestFlight** | `true` | 自动提交到 TestFlight |

如果需要修改，可以直接编辑 GitHub 仓库中的 `codemagic.yaml` 文件。

---

## 🚦 步骤 5：触发首次构建

### 方式 1：推送 Tag（推荐）

在本地执行：

```bash
# 1. 确保代码已提交
git status

# 2. 创建版本 Tag
git tag v1.1.0

# 3. 推送 Tag 到 GitHub
git push origin v1.1.0
```

**这会自动触发 Codemagic 构建！**

### 方式 2：手动触发（测试用）

在 Codemagic 中：
1. 进入应用主页
2. 点击 **"Start new build"**
3. 选择 `ios-release` 工作流
4. 选择分支：`main`
5. 点击 **"Start new build"**

---

## 📊 步骤 6：监控构建进度

### 6.1 查看构建日志

1. 构建开始后，点击进入构建详情页
2. 实时查看日志输出
3. 构建大约需要 **10-15 分钟**

### 6.2 构建流程

你会看到以下步骤：

```
✓ Set up debug log
✓ Get Flutter packages
✓ Install pods
✓ Flutter analyze
✓ Flutter test
✓ Flutter build ipa
✓ Publishing to App Store Connect
```

### 6.3 邮件通知

构建完成后，你会收到邮件通知（184232456@qq.com）：
- ✅ 成功：邮件包含下载链接
- ❌ 失败：邮件包含错误日志链接

---

## 📱 步骤 7：在 App Store Connect 提交审核

### 7.1 等待 TestFlight 处理

1. 构建成功后，等待 **10-30 分钟**
2. Apple 需要处理你的构建
3. 你会收到 Apple 的邮件通知

### 7.2 访问 App Store Connect

1. 访问：https://appstoreconnect.apple.com/
2. 登录你的账号
3. 进入 **"我的 App"**
4. 选择你的应用（`app.numforlife.com`）

### 7.3 填写应用元数据

在提交审核前，需要完成：

1. **应用信息**：
   - 应用名称
   - 副标题
   - 分类

2. **定价与销售范围**：
   - 选择国家/地区
   - 定价（免费或付费）

3. **截图**：
   - 上传不同尺寸的应用截图
   - 至少需要 6.5" 和 5.5" 的截图

4. **应用预览和描述**：
   - 应用描述
   - 关键词
   - 支持 URL

5. **版本信息**：
   - 版本号：1.1.0
   - 新功能说明

### 7.4 提交审核

1. 所有信息填写完整后
2. 点击 **"提交以供审核"**
3. 等待 Apple 审核（通常 **1-3 天**）

---

## 🔍 常见问题排查

### Q1：构建失败 - "No code signing identities found"

**原因**：证书配置不正确

**解决**：
1. 检查步骤 3 中的证书是否正确上传
2. 确认 Bundle ID 匹配：`app.numforlife.com`
3. 确认 Provisioning Profile 包含该 Bundle ID

---

### Q2：构建失败 - "Flutter analyze errors"

**原因**：代码中有语法错误或警告

**解决**：
1. 在本地运行：`flutter analyze`
2. 修复所有错误
3. 重新推送代码和 Tag

---

### Q3：构建成功但 TestFlight 没有看到

**原因**：Apple 还在处理

**解决**：
- 等待 10-30 分钟
- 检查邮箱是否收到 Apple 的通知
- 刷新 App Store Connect 页面

---

### Q4：如何更新应用？

**流程**：
1. 修改代码
2. 更新 `pubspec.yaml` 中的版本号（如 1.1.0 → 1.2.0）
3. 更新 `android/app/build.gradle.kts` 中的 `versionCode`
4. 提交代码
5. 推送新 Tag：`git tag v1.2.0 && git push origin v1.2.0`
6. 自动触发构建

---

## 📈 使用建议

### 节省构建时间

1. **本地验证后再推送**：
   ```bash
   flutter analyze
   flutter test
   flutter build ios --release
   ```

2. **只在准备发布时推送 Tag**：
   - 开发阶段：正常 `git push`（不触发构建）
   - 准备发布：`git tag v1.x.x && git push origin v1.x.x`（触发构建）

3. **使用语义化版本**：
   - 主版本：`v2.0.0`（大改动）
   - 次版本：`v1.1.0`（新功能）
   - 修订版：`v1.1.1`（Bug 修复）

---

## 🎯 下一步

完成配置后：

1. ✅ 推送第一个 Tag 测试构建
2. ✅ 验证 TestFlight 是否收到构建
3. ✅ 在 App Store Connect 完善应用信息
4. ✅ 提交审核

---

## 📞 需要帮助？

如果遇到问题，告诉我：
- 构建日志中的错误信息
- 在哪一步遇到困难
- 截图错误提示

我会帮你解决！

---

**祝你发布顺利！🚀**

创建日期：2025-12-10
