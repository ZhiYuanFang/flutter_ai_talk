# GitHub 打包 iOS IPA（无 Mac 方案）

本仓库已提供 GitHub Actions 工作流 [.github/workflows/build-ios-ipa.yml](../.github/workflows/build-ios-ipa.yml)，可在 GitHub 的 macOS Runner 上构建 iPhone 可安装的 iOS 包，并可直接上传到 App Store Connect / TestFlight。

如果你想看一份更适合直接照做的清单版文档，可先看：[docs/ios-github-actions-checklist.md](docs/ios-github-actions-checklist.md)。

如果你手上没有 Mac，**最推荐的发布路径是：`app-store` + `upload_to_testflight=true`**。这样 GitHub 会帮你完成构建和上传，后续你只需要在网页上进入 App Store Connect 完成测试分发或提审。

## 先看结论：你应该怎么选

### 方案 A：发给自己或测试同事安装（最推荐）

- 选择 `export_method=app-store`
- 选择 `upload_to_testflight=true`
- GitHub Actions 会把构建结果上传到 App Store Connect
- 你在 iPhone 上安装 `TestFlight`，就能从 TestFlight 安装应用

**优点**：不需要本地 Mac，也不需要手工上传 `.ipa`。

### 方案 B：直接生成可安装 IPA 给少量设备

- 选择 `export_method=ad-hoc`
- 不开启 `upload_to_testflight`
- 你的描述文件必须包含目标 iPhone 的 UDID

**优点**：适合有限设备侧载。

**缺点**：设备管理更麻烦，且没有 TestFlight 方便。

### 方案 C：开发调试机安装

- 选择 `export_method=development`

**适合**：内部调试、少量开发测试。

**不推荐作为正式分发方案**。

## 整体流程总览

你可以按下面顺序准备：

1. 在 Apple Developer 注册 App ID（Bundle ID）
2. 在 App Store Connect 创建 App 记录
3. 准备签名证书 `.p12`
4. 准备描述文件 `.mobileprovision`
5. 准备 App Store Connect API Key（用于 GitHub 自动上传 TestFlight）
6. 把这些内容放到 GitHub 仓库的 Secrets
7. 在 GitHub Actions 里运行工作流
8. 到 App Store Connect 里查看构建结果、发 TestFlight 或提交审核

下面逐步展开。

## 第 1 步：在 Apple Developer 创建 Bundle ID

这里的“Apple 后台”指的是 **Apple Developer 后台**，不是 App Store Connect。

你后面会同时用到两个平台：

- Apple Developer：创建 `Bundle ID`、证书、描述文件
- App Store Connect：创建 App、查看 TestFlight、提交审核

常用入口：

- Apple Developer 首页：<https://developer.apple.com/account/>
- Identifiers：<https://developer.apple.com/account/resources/identifiers/list>
- Profiles：<https://developer.apple.com/account/resources/profiles/list>
- App Store Connect：首页 <https://appstoreconnect.apple.com/>

打开 Apple Developer 后台：

- `Certificates, Identifiers & Profiles`
- 进入 `Identifiers`
- 点击 `+`
- 选择 `App IDs`
- 选择 `App`
- 填写：
  - `Description`：随便填，例如 `Pangbao App`
  - `Bundle ID`：例如 `com.fzy.pangbao`

注意：

- 这个 `Bundle ID` 之后要同时填到 GitHub Secret `IOS_BUNDLE_ID`
- **不能包含下划线 `_`**
- 一旦上线，通常不要随意更改

如果你要用微信 iOS Universal Link，后续还要在 Apple 后台和你自己的域名侧完成 Associated Domains 配置。

## 第 2 步：在 App Store Connect 创建 App 记录

打开 App Store Connect：

- `Apps`
- 点击 `+`
- 选择 `New App`

填写：

- `Platform`: iOS
- `Name`: 你的应用名
- `Primary Language`: 你的主要语言
- `Bundle ID`: 选择上一步创建的 Bundle ID
- `SKU`: 自定义唯一值，例如 `pangbao-ios-001`

这一步不是上传包，但建议先建好，否则后面上传到 TestFlight 时不容易核对。

## 第 3 步：准备签名证书 `.p12`

GitHub Actions 需要的是 **`.p12` 证书文件**，不是单独的 `.cer` 文件。

### 3.1 你需要什么类型的证书

按用途选择：

- `app-store` / `ad-hoc`：一般使用 **Apple Distribution**
- `development`：一般使用 **Apple Development**

如果你走 **TestFlight / App Store**，优先准备 **Apple Distribution** 证书。

### 3.2 如果团队里已经有人有 `.p12`

这是最省事的方式：

- 直接让有 Mac 的同事从钥匙串导出 `.p12`
- 同时问清楚导出密码
- 你拿到后放到本机，例如：`D:\certs\ios_distribution.p12`

### 3.3 如果你没有 Mac，也没有现成 `.p12`

可以在 Windows 上先生成私钥和 CSR，再去 Apple 后台申请证书，最后导出成 `.p12`。

#### 3.3.1 安装 OpenSSL

确保你本机有 `openssl` 命令。如果没有，可以安装 Git for Windows 或单独安装 OpenSSL。

#### 3.3.2 在 Windows 生成私钥和 CSR

PowerShell：

```powershell
cd D:\certs
openssl req -new -newkey rsa:2048 -nodes -keyout ios_dist.key -out ios_dist.csr -subj "/emailAddress=you@example.com,CN=Your Name,C=CN"
```

生成后会得到：

- `ios_dist.key`：私钥，请妥善保管
- `ios_dist.csr`：上传到 Apple 用的 CSR 文件

#### 3.3.3 在 Apple Developer 创建证书

打开 Apple Developer：

- `Certificates, Identifiers & Profiles`
- `Certificates`
- 点击 `+`
- 选择：
  - `Apple Distribution`（用于 TestFlight / App Store / Ad Hoc）
  - 或 `Apple Development`（用于 Development）
- 上传刚生成的 `ios_dist.csr`
- 下载返回的证书文件，例如 `ios_distribution.cer`

#### 3.3.4 把 `.cer` 转成 `.p12`

PowerShell：

```powershell
cd D:\certs
openssl x509 -in ios_distribution.cer -inform DER -out ios_distribution.pem -outform PEM
openssl pkcs12 -export -inkey ios_dist.key -in ios_distribution.pem -out ios_distribution.p12
```

执行第二条命令时会要求你输入导出密码。

最终你会得到：

- `ios_distribution.p12`
- 这个密码就是后面 GitHub Secret `IOS_CERTIFICATE_PASSWORD`

## 第 4 步：准备描述文件 `.mobileprovision`

描述文件要和证书类型、Bundle ID、分发方式匹配。

打开 Apple Developer：

- `Certificates, Identifiers & Profiles`
- `Profiles`
- 点击 `+`

### 如果你要走 TestFlight / App Store

选择：

- `App Store` 或 Apple 当前后台对应的 `App Store Connect` 分发类型

然后按顺序选择：

1. 你的 App ID（Bundle ID）
2. 对应的 `Apple Distribution` 证书
3. 命名 profile，例如 `pangbao-appstore`
4. 下载 `.mobileprovision`

### 如果你要走 Ad Hoc

选择：

- `Ad Hoc`

然后按顺序选择：

1. 你的 App ID
2. 对应的 `Apple Distribution` 证书
3. 选择测试设备（这些设备的 UDID 必须提前在 `Devices` 中登记）
4. 下载 `.mobileprovision`

### 如果你要走 Development

选择：

- `iOS App Development`

然后按顺序选择：

1. 你的 App ID
2. 对应的 `Apple Development` 证书
3. 选择测试设备
4. 下载 `.mobileprovision`

## 第 5 步：准备 App Store Connect API Key（用于自动上传）

如果你只想让 GitHub 生成 `.ipa`，这一步可以先不做。

如果你希望 **GitHub 直接把包上传到 App Store Connect / TestFlight**，则必须做这一步。

打开 App Store Connect：

- `Users and Access`
- `Integrations`
- `App Store Connect API`
- 点击 `Generate API Key`

创建后你会拿到：

- `Key ID`
- `Issuer ID`
- 下载的 `.p8` 文件（只提供下载一次）

你需要保存好这三项，它们会分别进入 GitHub Secrets：

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`

## 第 6 步：把证书和密钥放到哪里

所有敏感信息都放到 **GitHub 仓库的 Secrets**，不是放进代码仓库。

路径：

- GitHub 仓库首页
- `Settings`
- `Secrets and variables`
- `Actions`
- `New repository secret`

### 必填 Secrets

| Secret | 你要填什么 | 从哪里来 |
|------|------|------|
| `IOS_BUNDLE_ID` | iOS Bundle ID，例如 `com.fzy.pangbao` | Apple Developer -> Identifiers |
| `IOS_TEAM_ID` | Apple Team ID | Apple Developer 账号信息 |
| `IOS_CERTIFICATE_P12_BASE64` | `.p12` 文件的 Base64 | 你导出的 `ios_distribution.p12` 或 `ios_development.p12` |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` 导出密码 | 导出 `.p12` 时设置 |
| `IOS_MOBILEPROVISION_BASE64` | `.mobileprovision` 的 Base64 | Apple Developer -> Profiles 下载 |

### 推荐 Secrets

| Secret | 用途 |
|------|------|
| `IOS_APP_DISPLAY_NAME` | iPhone 桌面显示名称 |
| `IOS_MICROPHONE_USAGE_DESCRIPTION` | 麦克风权限文案 |
| `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` | 语音识别权限文案 |
| `WECHAT_APP_ID` | 微信移动应用 AppId |
| `WECHAT_UNIVERSAL_LINK` | 微信 iOS Universal Link |

### 自动上传 TestFlight 时必填

| Secret | 你要填什么 | 从哪里来 |
|------|------|------|
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | App Store Connect API Key 页面 |
| `APP_STORE_CONNECT_KEY_ID` | Key ID | App Store Connect API Key 页面 |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | `.p8` 文件 Base64 | 下载的 API Key 文件 |

## 第 7 步：Windows 下如何把文件转成 Base64

PowerShell：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\ios_distribution.p12'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\profile.mobileprovision'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\AuthKey_ABC1234567.p8'))
```

输出后分别复制到对应 Secret：

- `.p12` -> `IOS_CERTIFICATE_P12_BASE64`
- `.mobileprovision` -> `IOS_MOBILEPROVISION_BASE64`
- `.p8` -> `APP_STORE_CONNECT_API_KEY_P8_BASE64`

## 第 8 步：如何运行 GitHub Actions 打包

1. 把代码推送到 GitHub
2. 打开仓库的 `Actions`
3. 选择 `Build iOS IPA`
4. 点击 `Run workflow`
5. 选择参数：
   - `export_method=app-store`：用于 TestFlight / App Store
   - `upload_to_testflight=true`：让 GitHub 自动上传到 App Store Connect
   - `flutter_version`：默认 `3.24.5`，通常不用改
   - `macos_runner`：macOS Runner 镜像，默认 `macos-26`（可选 `macos-14` / `macos-15` / `macos-26-intel`）
   - `xcode_version`：指定 Xcode 版本，默认 `26.4`（需与所选 Runner 镜像匹配，如 `macos-15` 常用 `16.2`）
   - `build_name`：可选，例如 `1.0.0`
   - `build_number`：可选，例如 `12`

如果你只是想先验证签名能不能过，也可以：

- `export_method=ad-hoc`
- `upload_to_testflight=false`

## 第 9 步：构建时 GitHub 会自动做什么

工作流会自动：

- 如果仓库里暂时没有 `app/ios/`，执行 `flutter create . --platforms=ios`
- 把 `WECHAT_APP_ID` / `WECHAT_UNIVERSAL_LINK` 注入到 `app/pubspec.yaml`
- 为 `speech_to_text` / `record` 自动补齐 iOS 权限文案
- 导入证书和描述文件
- 切换至指定 Xcode 版本并打印 iOS SDK 信息
- 修改 iOS 工程签名配置
- 执行 `flutter build ipa`
- 上传 `.ipa` artifact
- 在你开启 `upload_to_testflight=true` 时，自动上传到 App Store Connect

## 第 10 步：构建成功后去哪里看结果

### 如果你没开启自动上传

构建完成后，在 GitHub Actions 任务页面下载 artifact：

- `ipa-<export_method>`：打好的 `.ipa`
- `xcarchive-<export_method>`：归档包

### 如果你开启了自动上传

去 App Store Connect：

- `My Apps`
- 打开你的 App
- `TestFlight`

一般上传成功后，Apple 需要一段时间处理构建，处理完成后你会在 TestFlight 页面看到新 build。

## 第 11 步：如何把 IPA 上传到 App Store / TestFlight

### 最推荐：让 GitHub 直接上传

这是你目前最适合的方式，因为你没有 Mac。

做法：

- `export_method=app-store`
- `upload_to_testflight=true`

这样 GitHub 会在构建后执行上传。

### 如果你只下载了 IPA，能不能在 Windows 手工上传？

通常**不推荐**。Apple 官方常用的 `Transporter` 和很多上传工具主要面向 macOS。

所以对你来说，最稳的是：

- **不要在 Windows 上手工传**
- **直接让 GitHub Actions 代传**

## 第 12 步：上传后如何发布到 TestFlight

当 build 出现在 App Store Connect -> TestFlight 后：

### 内部测试

1. 打开 `TestFlight`
2. 选择 `Internal Testing`
3. 添加内部测试人员
4. 选择刚上传的 build
5. 测试人员在 iPhone 安装 `TestFlight` 后即可安装

### 外部测试

1. 打开 `TestFlight`
2. 选择 `External Testing`
3. 创建测试组
4. 提交 Beta 审核（外部测试一般需要）
5. 审核通过后邀请外部测试人员

## 第 13 步：如何正式上架 App Store

上传到 App Store Connect 只是第一步，**不等于已经上架**。

你还需要在 App Store Connect 网页里完成：

1. 应用基础信息
2. 隐私政策 URL
3. 应用截图
4. 年龄分级
5. App Privacy 隐私申报
6. 如有账号登录，提供审核账号
7. 选择一个已上传成功的 build
8. 点击 `Submit for Review`

也就是说：

- **GitHub Actions 负责“打包 + 上传到 App Store Connect”**
- **你在网页里负责“填写元数据 + 提交审核 + 正式发布”**

## 常见问题

### 1. 证书应该提供到哪里？

提供到 GitHub 仓库的：

- `Settings`
- `Secrets and variables`
- `Actions`

不要提交到仓库源码中。

### 2. 我应该给你哪些文件？

至少这些：

- `.p12`
- `.mobileprovision`
- `.p12` 密码
- `IOS_BUNDLE_ID`
- `IOS_TEAM_ID`

如果还要自动上传 TestFlight，再加：

- `.p8`
- `Key ID`
- `Issuer ID`

### 3. 没有 Mac，能不能上 App Store？

可以，但前提是：

- 你能拿到正确的签名证书和描述文件
- 或你能自己在 Apple Developer 后台生成这些签名材料
- 然后通过 GitHub Actions 完成构建和上传

### 4. 为什么推荐 TestFlight？

因为你没有 Mac，而 TestFlight 是最省心的 iPhone 安装方式：

- 不用折腾本地上传工具
- 不用手工签名安装
- 安装体验更接近正式上架前流程

## 注意事项

- `IOS_BUNDLE_ID` 不要包含下划线 `_`
- 证书类型、描述文件类型、Bundle ID、Team ID 必须完全匹配
- 当前仓库原本没有提交 `app/ios/`；工作流会在 CI 中临时生成，因此如果你后续要长期维护 iOS 原生配置，建议未来把 `app/ios/` 正式纳入仓库
- 微信登录在 iOS 上要真正可用，除了工作流 secrets 外，还需要 Apple Associated Domains、你的域名 `apple-app-site-association`、微信开放平台配置三者一致
- 上传成功后，App Store Connect 处理 build 可能要等待几分钟到几十分钟
