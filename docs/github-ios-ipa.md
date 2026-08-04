# GitHub 打包 iOS IPA（无 Mac 方案）

本仓库已改为 **三入口工作流**，通过 GitHub macOS Runner 构建 iOS IPA 并按目标分发：

- ad-hoc：上传到蒲公英
- testflight：上传到 TestFlight（测试组可选）
- appstore：仅上传到 App Store Connect（ASC）

工作流入口：

- [.github/workflows/build-ios-adhoc.yml](../.github/workflows/build-ios-adhoc.yml)
- [.github/workflows/build-ios-testflight.yml](../.github/workflows/build-ios-testflight.yml)
- [.github/workflows/build-ios-appstore.yml](../.github/workflows/build-ios-appstore.yml)

> 旧入口 [.github/workflows/build-ios-ipa.yml](../.github/workflows/build-ios-ipa.yml) 已退场，不再作为手工触发入口。

如果你想看一份更适合直接照做的清单版文档，可先看：[docs/ios-github-actions-checklist.md](docs/ios-github-actions-checklist.md)。

## 发布入口对照（推荐只看这个）

- `Build iOS ad-hoc`：固定 `ad-hoc` 导出，自动上传蒲公英；蒲公英上传失败会直接导致 workflow 失败。
- `Build iOS TestFlight`：固定 `app-store` 导出并上传 TestFlight；`internal_testflight_groups` 为可选，留空则仅上传不自动分组。
- `Build iOS AppStore Upload`：固定 `app-store` 导出并上传 ASC；仅上传，不自动提审、不自动发布。

## 先看结论：你应该怎么选

### 方案 A：发给测试同事快速安装（推荐）

- 选择 `Build iOS TestFlight`
- 可选填写 `internal_testflight_groups`（支持逗号分隔）
- 不填也可上传成功，后续在 ASC 手工分配组

### 方案 B：需要 ad-hoc 外部分发链接

- 选择 `Build iOS ad-hoc`
- 配置 `PGYER_API_KEY`（Repository Secrets）
- 可选配置安装密码和更新说明

### 方案 C：准备上架资产但不自动提审

- 选择 `Build iOS AppStore Upload`
- 构建仅上传到 ASC，后续由你在网页里手工提审/发布

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

### 桌面小组件（App Groups + Widget Extension，2026-03 起必需）

若仓库已启用 `PangbaoWidget`，Archive **必须**主 App 与 Extension **各一份**描述文件，且均含 App Group `group.com.fzy.pangbao.widget`。

**Apple Developer 网页（无 Mac）：**

1. **Identifiers → App Groups** → 新建 `group.com.fzy.pangbao.widget`
2. App ID **`IOS_BUNDLE_ID`**（如 `com.fzy.pangbao`）→ Capabilities → **App Groups** → 勾选上述 group → Save → **Profiles 里重新生成** `pangbao-appstore`（旧 profile 不含 App Groups 会导致 Archive 失败）
3. 新建 App ID **`IOS_WIDGET_BUNDLE_ID`**（默认 `com.fzy.pangbao.widget`，即 `{IOS_BUNDLE_ID}.widget`）→ 同样启用 **App Groups**
4. **Profiles → +** → App Store → 选 Extension App ID → 生成如 `pangbao-widget-appstore` → 下载

**GitHub Secrets（Base64 编码 `.mobileprovision`）：**

| Secret | 说明 |
|--------|------|
| `IOS_MOBILEPROVISION_APPSTORE_BASE64` | 主 App（已含 App Groups 的新 profile） |
| `IOS_MOBILEPROVISION_WIDGET_APPSTORE_BASE64` | Widget Extension |
| `IOS_WIDGET_BUNDLE_ID` | 可选；默认 `{IOS_BUNDLE_ID}.widget`（如 `com.fzy.pangbao.widget`） |

Ad Hoc / Development 同理：`IOS_MOBILEPROVISION_WIDGET_ADHOC_BASE64` 等。

CI 会在构建前运行 `validate_ios_workflow_secrets.py` 校验 Bundle ID、Team、App Group 与过期时间。Flutter 版本默认读仓库根 **`.fvmrc`**（workflow 填 `pinned`）。`home_widget` **≥0.9**（含 iOS SPM）。Extension 由 `ensure_pangbao_widget_target.rb` 创建，并链接 SPM 包 `FlutterGeneratedPluginSwiftPackage` 以 `import home_widget`（**禁止**给 Extension 单独 CocoaPods `home_widget`），**无需本地 Xcode**。

详见 `app/ios/PangbaoWidget/README.md`。

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

### 通用必填 Secrets（所有入口）

| Secret | 你要填什么 | 从哪里来 |
| ------ | ------ | ------ |
| `IOS_BUNDLE_ID` | iOS Bundle ID，例如 `com.fzy.pangbao` | Apple Developer -> Identifiers |
| `IOS_TEAM_ID` | Apple Team ID | Apple Developer 账号信息 |
| `IOS_CERTIFICATE_P12_BASE64` | `.p12` 文件的 Base64 | 你导出的 `ios_distribution.p12` 或 `ios_development.p12` |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` 导出密码 | 导出 `.p12` 时设置 |
| `WECHAT_APP_ID` | 微信移动应用 AppId | 微信开放平台 |
| `WECHAT_UNIVERSAL_LINK` | 微信 iOS Universal Link | 微信开放平台 |

### 描述文件 Secrets（按入口）

优先使用分入口描述文件；兼容兜底 `IOS_MOBILEPROVISION_BASE64`。

| 入口 | 首选 Secret |
| ------ | ------ |
| ad-hoc | `IOS_MOBILEPROVISION_ADHOC_BASE64` |
| testflight | `IOS_MOBILEPROVISION_APPSTORE_BASE64` |
| appstore | `IOS_MOBILEPROVISION_APPSTORE_BASE64` |

### 推荐 Secrets（通用）

| Secret | 用途 |
| ------ | ------ |
| `IOS_APP_DISPLAY_NAME` | iPhone 桌面显示名称 |
| `IOS_MICROPHONE_USAGE_DESCRIPTION` | 麦克风权限文案 |
| `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` | 语音识别权限文案 |
| `WECHAT_APP_ID` | 微信移动应用 AppId |
| `WECHAT_UNIVERSAL_LINK` | 微信 iOS Universal Link |
| `IOS_ASSOCIATED_DOMAIN` | iOS Associated Domains，格式 `applinks:<domain>` |

### ad-hoc（蒲公英）额外必填

| Secret | 用途 |
| ------ | ------ |
| `PGYER_API_KEY` | 蒲公英上传 API Key |

> 配置路径：Repository -> Settings -> Secrets and variables -> Actions -> New repository secret

### TestFlight / AppStore Upload 额外必填

| Secret | 你要填什么 | 从哪里来 |
| ------ | ------ | ------ |
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
3. 选择对应入口：
   - `Build iOS ad-hoc`
   - `Build iOS TestFlight`
   - `Build iOS AppStore Upload`
4. 点击 `Run workflow`

### Build iOS ad-hoc

- 固定 ad-hoc 导出并上传蒲公英
- 构建时自动注入 `API_BASE_URL=https://test.pangbao.cuplay.top`（测试网关；WebSocket 与相对资源 URL 由该基址推导）
- TestFlight / App Store 入口不注入测试基址，仍使用 `AppEnv` 默认生产网关
- 必须配置 `PGYER_API_KEY`
- 可选填写：`pgyer_update_description`、`pgyer_install_password`
- 蒲公英上传失败将直接失败（硬失败）

### Build iOS TestFlight

- 固定 app-store 导出并上传 TestFlight
- `internal_testflight_groups` 可选：
  - 不为空：尝试自动分组
  - 为空：仅上传，不自动分组（日志会提示）

### Build iOS AppStore Upload

- 固定 app-store 导出并上传 ASC
- 仅上传，不自动提审、不自动发布

## 第 9 步：构建时 GitHub 会自动做什么

工作流会自动：

- 如果仓库里暂时没有 `app/ios/`，执行 `flutter create . --platforms=ios`
- 把 `WECHAT_APP_ID` / `WECHAT_UNIVERSAL_LINK` 注入到 `app/pubspec.yaml`
- 在 `flutter build ipa` 时显式注入 `--dart-define=WECHAT_APP_ID=...` 与 `--dart-define=WECHAT_UNIVERSAL_LINK=...`
- ad-hoc 入口额外注入 `--dart-define=API_BASE_URL=https://test.pangbao.cuplay.top`
- fail-fast 校验：`WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 不得为空
- 校验 `WECHAT_UNIVERSAL_LINK` 为 `https://` 且不含 `*`，并校验其域名与 `IOS_ASSOCIATED_DOMAIN` 一致
- 为 `speech_to_text` / `record` 自动补齐 iOS 权限文案
- 导入证书和描述文件
- 切换至指定 Xcode 版本并打印 iOS SDK 信息
- 修改 iOS 工程签名配置
- 执行 `flutter build ipa`
- 上传 `.ipa` 与 `xcarchive` artifact
- ad-hoc 入口：自动上传蒲公英（失败即 workflow 失败）
- testflight 入口：上传 TestFlight；若配置组则自动分组
- appstore 入口：仅上传到 ASC

## 第 10 步：构建成功后去哪里看结果

构建完成后，在 GitHub Actions 任务页面都可以下载 artifact：

- `ipa-adhoc` / `ipa-testflight` / `ipa-appstore`
- `xcarchive-adhoc` / `xcarchive-testflight` / `xcarchive-appstore`

按入口看分发结果：

- ad-hoc：在日志看到蒲公英上传成功（不强制输出安装短链）
- testflight：在 App Store Connect -> TestFlight 查看 build；可自动分组或手工分组
- appstore：在 ASC 中可见上传的 build（仅上传）

## 第 11 步：如何把 IPA 上传到 App Store / TestFlight

### 最推荐：让 GitHub 直接上传

这是你目前最适合的方式，因为你没有 Mac。

做法：

- 选择 `Build iOS TestFlight`
- 可选填写 `internal_testflight_groups=<你的内部测试组名>`（可留空）

这样 GitHub 会在构建后执行上传。

如果你的目标是 ad-hoc 分发到外部设备，使用 `Build iOS ad-hoc`，并确保已配置 `PGYER_API_KEY`。

### 如果你只下载了 IPA，能不能在 Windows 手工上传？

通常**不推荐**。Apple 官方常用的 `Transporter` 和很多上传工具主要面向 macOS。

所以对你来说，最稳的是：

- **不要在 Windows 上手工传**
- **直接让 GitHub Actions 代传**

## 第 12 步：上传后如何发布到 TestFlight

当 build 出现在 App Store Connect -> TestFlight 后：

### 内部测试

如果你在 `Build iOS TestFlight` 中填写了 `internal_testflight_groups` 且组名正确，工作流会尝试自动分配。若日志提示“上传成功但分配失败”，可按下面手工补救：

1. 打开 `TestFlight`
2. 进入对应 Build
3. 选择 `Internal Testing`
4. 手工勾选组并保存

分配完成后，测试人员在 iPhone 安装 `TestFlight` 即可安装对应 build。

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

### App Store 商品页「语言」字段

App Store 商品页「信息 → 语言」（例如显示「英语」或「中文」）来自 **IPA 二进制** 所声明的 iOS 本地化（`CFBundleLocalizations`、`zh-Hans.lproj` 等），**不是** App Store Connect 里商品描述的语言。

CI 在 `app/tool/ci/prepare_ios_project.sh` 中会写入 `zh-Hans` 声明。修改后须 **重新上传新 build** 并等待 App Store Connect 处理完成，商品页语言标签才会更新；仅改 ASC 文案无法单独修复该字段。

上传后在 ASC 打开对应 build，确认 **Included Localizations** 含 **Chinese (Simplified)**，再核对 [App Store 商品页](https://apps.apple.com/cn/app/%E8%83%96%E5%AE%9D/id6774418472) 的「语言」是否为中文。

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

如果要走 ad-hoc 自动上传蒲公英，再加：

- `PGYER_API_KEY`

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

### 6. 蒲公英为什么上传失败会让工作流失败？

因为 ad-hoc 入口的目标就是“构建并完成蒲公英分发”。若上传失败，结果不可用，所以 workflow 采用硬失败策略，避免出现“构建成功但分发失败”的灰色状态。

### 5. `pod install` 报 speech_to_text 需要更高 deployment target？

本仓库依赖 `speech_to_text`（iOS 13+）与 `ffmpeg_kit_flutter_new_min_gpl`（iOS 14+）。CI 会在 `prepare_ios_project.sh` 中把 `Podfile` 设为 `platform :ios, '14.0'`，并同步 Runner 与 Pods 的 `IPHONEOS_DEPLOYMENT_TARGET`。若本地自行生成 `ios/` 后遇到 CocoaPods「required a higher minimum deployment target」，请确认 `ios/Podfile` 已取消注释并设为 `platform :ios, '14.0'`，再执行 `pod install --repo-update`。

### 7. `pod install` 报 `Error installing WechatOpenSDK-XCFramework`（curl dldir1.qq.com 失败）？

`fluwx` 依赖的 `WechatOpenSDK-XCFramework` 默认从腾讯 CDN 下载，在 **Xcode Cloud、GitHub Actions、海外网络** 等环境常失败。

本仓库已 **vendored** 到 `app/ios/Vendor/WechatOpenSDK-XCFramework/`，`prepare_ios_project.sh` 会在 `Podfile` 中注入本地 pod，不再走远程下载。

**本地修复步骤：**

```bash
cd app
bash tool/ci/prepare_ios_project.sh   # 确保 vendored SDK 存在并 patch Podfile
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

若 `ios/Vendor/WechatOpenSDK-XCFramework/WechatOpenSDK.xcframework` 缺失，可手动执行 `bash tool/ci/vendor_wechat_opensdk.sh`（需能访问 `dldir1.qq.com`），或从已提交仓库拉取该目录。

## 注意事项

- `IOS_BUNDLE_ID` 不要包含下划线 `_`
- 证书类型、描述文件类型、Bundle ID、Team ID 必须完全匹配
- 当前仓库原本没有提交 `app/ios/`；工作流会在 CI 中临时生成，因此如果你后续要长期维护 iOS 原生配置，建议未来把 `app/ios/` 正式纳入仓库
- 微信登录在 iOS 上要真正可用，除了工作流 secrets 外，还需要 Apple Associated Domains、你的域名 `apple-app-site-association`、微信开放平台配置三者一致
- `WECHAT_UNIVERSAL_LINK` 必须填写完整 `https://域名/路径前缀/`，不要填写 `*` 通配符
- 建议把 `IOS_ASSOCIATED_DOMAIN` 填成 `applinks:<WECHAT_UNIVERSAL_LINK 对应域名>`，便于 CI 自动校验
- 上传成功后，App Store Connect 处理 build 可能要等待几分钟到几十分钟
