# iOS 打包发布速查清单（无 Mac）

这份文档是给你**直接照着操作**用的，适合当前项目：

- 项目目录：`app/`
- 当前仓库没有 `app/ios/`
- 使用 GitHub Actions 在 macOS Runner 上远程构建 `.ipa`
- 推荐发布路径：`release_mode=testflight_internal_only`

详细原理和完整说明见：

- [docs/github-ios-ipa.md](docs/github-ios-ipa.md)
- [.github/workflows/build-ios-ipa.yml](../.github/workflows/build-ios-ipa.yml)

---

## 一、你最终要做的事

按这个顺序做：

1. 在 Apple Developer 后台创建 iOS App 的 `Bundle ID`
2. 在 App Store Connect 创建 App
3. 准备证书 `.p12`
4. 准备描述文件 `.mobileprovision`
5. 准备 App Store Connect API Key（`.p8`）
6. 把这些内容填到 GitHub `Secrets`
7. 运行 GitHub Actions 工作流
8. 到 App Store Connect / TestFlight 查看结果
9. 如需上架，再在 App Store Connect 网页里提交审核

---

## 二、你需要准备哪些内容

## 补充说明：这里的“Apple 后台”具体指什么

你后面会同时用到 **两个不同的 Apple 平台**：

### 1. Apple Developer 后台

这个后台主要用来处理：

- `Bundle ID`
- 证书 `Certificates`
- 描述文件 `Profiles`
- 测试设备 `Devices`

常用入口：

- Apple Developer 账号首页：<https://developer.apple.com/account/>
- Identifiers（创建 `Bundle ID`）：<https://developer.apple.com/account/resources/identifiers/list>
- Profiles（创建描述文件）：<https://developer.apple.com/account/resources/profiles/list>

### 2. App Store Connect 后台

这个后台主要用来处理：

- 创建 App 记录
- 生成 App Store Connect API Key
- 查看 TestFlight 构建
- 提交 App Store 审核

常用入口：

- App Store Connect 首页：<https://appstoreconnect.apple.com/>
- 登录入口：<https://appstoreconnect.apple.com/login>

### 一句话区分

- **创建 `Bundle ID`、证书、描述文件**：去 **Apple Developer 后台**
- **创建 App、看 TestFlight、上架 App Store**：去 **App Store Connect 后台**

### 必须准备

| 名称 | 用途 | 你之后填到哪里 |
|------|------|------|
| `IOS_BUNDLE_ID` | App 的 iOS 包名 | GitHub Secret |
| `IOS_TEAM_ID` | Apple 团队 ID | GitHub Secret |
| `.p12` | iOS 签名证书 | 转 Base64 后填 GitHub Secret |
| `.p12` 密码 | 解锁证书 | GitHub Secret |
| `.mobileprovision` | iOS 描述文件 | 转 Base64 后填 GitHub Secret |

### 如果要自动上传 TestFlight，还必须准备

| 名称 | 用途 | 你之后填到哪里 |
|------|------|------|
| `Issuer ID` | App Store Connect API 鉴权 | GitHub Secret |
| `Key ID` | App Store Connect API 鉴权 | GitHub Secret |
| `.p8` | App Store Connect API Key 文件 | 转 Base64 后填 GitHub Secret |

### 可选准备

| 名称 | 用途 |
|------|------|
| `IOS_APP_DISPLAY_NAME` | iPhone 桌面显示的应用名 |
| `IOS_MICROPHONE_USAGE_DESCRIPTION` | 麦克风权限提示语 |
| `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` | 语音识别权限提示语 |
| `WECHAT_APP_ID` | 微信移动应用 AppId |
| `WECHAT_UNIVERSAL_LINK` | 微信 iOS Universal Link |

### Internal Only 模式额外必填（工作流输入）

| 名称 | 用途 | 填写位置 |
|------|------|------|
| `internal_testflight_groups` | 上传后自动分配的内部测试组（可逗号分隔） | Run workflow 输入参数 |

---

## 三、这些内容去哪里拿

### 1. `IOS_BUNDLE_ID`

这里说的后台是：**Apple Developer 后台**，不是 App Store Connect。

位置：Apple Developer → `Certificates, Identifiers & Profiles` → `Identifiers`

可直接打开：<https://developer.apple.com/account/resources/identifiers/list>

示例：

```text
com.fzy.pangbao
```

要求：

- 不能有下划线 `_`
- 后续不要随便修改

### 2. `IOS_TEAM_ID`

位置：Apple Developer 账号后台团队信息

示例：

```text
A1B2C3D4E5
```

### 3. `.p12` 证书

来源有两种：

#### 方案 A：让有 Mac 的同事导出给你

让同事导出：

- `Apple Distribution` 证书（推荐，适合 TestFlight / App Store）
- 或 `Apple Development` 证书（用于 development）

导出后你会拿到：

- `xxx.p12`
- 一个导出密码

#### 方案 B：你自己在 Windows 生成 CSR 再申请

你会得到：

- 私钥 `ios_dist.key`
- CSR `ios_dist.csr`
- Apple 下载的证书 `ios_distribution.cer`
- 最后转成 `ios_distribution.p12`

### 4. `.mobileprovision` 描述文件

位置：Apple Developer → `Certificates, Identifiers & Profiles` → `Profiles`

可直接打开：<https://developer.apple.com/account/resources/profiles/list>

按用途选：

- `app-store`：选择 `App Store` / `App Store Connect` 类型
- `ad-hoc`：选择 `Ad Hoc`
- `development`：选择 `iOS App Development`

### 5. `.p8` / `Issuer ID` / `Key ID`

位置：App Store Connect → `Users and Access` → `Integrations` → `App Store Connect API`

入口首页：<https://appstoreconnect.apple.com/>

创建 API Key 后会得到：

- `Issuer ID`
- `Key ID`
- 下载的 `.p8` 文件

注意：`.p8` 通常只能下载一次，务必保存好。

---

## 四、先在本机整理文件

建议你在 Windows 建一个目录，例如：

```text
D:\certs\
```

放进去：

```text
D:\certs\ios_distribution.p12
D:\certs\profile.mobileprovision
D:\certs\AuthKey_ABC123XYZ9.p8
```

如果你走 development，就把 `.p12` 换成 development 对应证书。

---

## 五、Windows 下转 Base64

PowerShell：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\ios_distribution.p12'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\profile.mobileprovision'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\certs\AuthKey_ABC123XYZ9.p8'))
```

复制输出结果备用。

---

## 六、GitHub 里具体填哪里

打开你的 GitHub 仓库：

1. 进入 `Settings`
2. 进入 `Secrets and variables`
3. 进入 `Actions`
4. 点击 `New repository secret`

然后逐个新增下面这些值。

---

## 七、GitHub Secrets 逐项填写模板

### 必填

#### 1. `IOS_BUNDLE_ID`

填：

```text
com.fzy.pangbao
```

#### 2. `IOS_TEAM_ID`

填：

```text
395D9NUCNF
```

#### 3. `IOS_CERTIFICATE_P12_BASE64`

填：

- 你刚刚把 `.p12` 文件转出来的那一长串 Base64 文本

#### 4. `IOS_CERTIFICATE_PASSWORD`

填：p12导出base64
```bash
 [Convert]::ToBase64String([IO.File]::ReadAllBytes('d:\work\flutter_ai_talk\app\ios\证书.p12'))
```

#### 5. `IOS_MOBILEPROVISION_BASE64`

填：

- 你刚刚把 `.mobileprovision` 转出来的那一长串 Base64 文本
```bash
 [Convert]::ToBase64String([IO.File]::ReadAllBytes('d:\work\flutter_ai_talk\app\ios\pangbaoappstore.mobileprovision'))
 ```

### 推荐填写

#### 6. `IOS_APP_DISPLAY_NAME`

示例：

```text
胖宝
```

#### 7. `IOS_MICROPHONE_USAGE_DESCRIPTION`

示例：

```text
需要麦克风权限以支持语音输入与录音
```

#### 8. `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION`

示例：

```text
需要语音识别权限以将语音转换为文字
```

#### 9. `WECHAT_APP_ID`

示例：

```text
wxe713de83c921f341
```

#### 10. `WECHAT_UNIVERSAL_LINK`

示例：

```text
https://www.pangbao.cuplay.top/wx/ulink/*
```

### 如果要自动上传 TestFlight，继续填

#### 11. `APP_STORE_CONNECT_ISSUER_ID`

示例：

```text
aef3e1e8-a07c-4577-9aba-d39f514e059a
```

#### 12. `APP_STORE_CONNECT_KEY_ID`

示例：

```text
DY56P86YR8
```

#### 13. `APP_STORE_CONNECT_API_KEY_P8_BASE64`

填：

- 你把 `.p8` 文件转出来的那一长串 Base64 文本
示例：

```text
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgIDfmIqb0Nbln+pRX
EdlxkFqPOvpw5DBCSjjcpJSfuVKgCgYIKoZIzj0DAQehRANCAAScDD38RlgmjbDT
M+QXZxe64oCA57aK6y9VXWmS3OMGiR+Ad0BnHtJjH0hRh/5+CU3o3YCDOZrA7QVJ
FIIU9h8G
```

---

## 八、然后去哪里点“开始打包”

打开 GitHub 仓库：

1. 点击 `Actions`
2. 选择 `Build iOS IPA`
3. 点击 `Run workflow`

你需要填的运行参数如下。

### 最推荐的参数（仅内部测试）

| 参数 | 建议值 |
|------|------|
| `release_mode` | `testflight_internal_only` |
| `internal_testflight_groups` | 例如 `Internal QA` |
| `export_method` | 可保留默认（会被模式自动约束） |
| `upload_to_testflight` | 可保留默认（在非 legacy 模式会被忽略） |
| `flutter_version` | `3.24.5` |
| `build_name` | 留空或填 `1.0.0` |
| `build_number` | 留空或填递增数字，例如 `1` |
| `app_dir` | `app` |

### 如果你只是先验证签名是否成功

| 参数 | 建议值 |
|------|------|
| `release_mode` | `ipa_only` |
| `export_method` | `ad-hoc` 或 `development` |
| `upload_to_testflight` | 保持任意值（`ipa_only` 下会被强制关闭） |
| `app_dir` | `app` |

### 模式对照（新增）

| `release_mode` | 目标 | TestFlight 上传 | 备注 |
|------|------|------|------|
| `ipa_only` | 只产出包 | 否 | 导出方式跟随 `export_method` |
| `testflight_internal_only` | 仅内部测试 | 是 | 需填写 `internal_testflight_groups` |
| `testflight_and_appstore` | 外测/上架准备 | 是 | 上传后在后台继续配置 |
| `legacy` | 老参数兼容 | 跟随旧参数 | 建议迁移 |

---

## 九、构建时会自动发生什么

当前仓库已经配置好，GitHub Actions 会自动：

- 检查你是否填了必须的 Secrets
- 如果项目没有 `app/ios/`，自动执行 `flutter create . --platforms=ios`
- 自动补 iOS 权限文案
- 导入证书和描述文件
- 配置 Xcode 签名
- 构建 `.ipa`
- `ipa_only` 模式：上传 IPA artifact，不上传 TestFlight
- TestFlight 相关模式：自动上传到 App Store Connect
- `testflight_internal_only`：额外尝试自动分配到 `internal_testflight_groups`

所以你现在**不用先自己创建 `app/ios/`**。

---

## 十、构建完去哪里看结果

### 情况 A：你没有开启上传 TestFlight

去 GitHub Actions 任务页，下载 artifact：

- `ipa-<release_mode>`
- `xcarchive-<release_mode>`

### 情况 B：你开启了上传 TestFlight

去 App Store Connect：

1. 进入 `My Apps`
2. 打开你的 App
3. 进入 `TestFlight`
4. 等 Apple 处理构建

看到 build 后：

- 内部测试：直接分配给内部测试成员
- 外部测试：按要求提交 Beta 审核

---

## 十一、如果要正式上架 App Store

GitHub Actions 只能帮你：

- 打包
- 上传到 App Store Connect

后续你还要在 App Store Connect 网页里完成：

- App 名称
- 描述
- 关键词
- 截图
- 年龄分级
- 隐私政策 URL
- App Privacy 隐私申报
- 审核说明
- 选择 build
- 点击 `Submit for Review`

也就是说：

- **GitHub Actions = 打包 + 上传**
- **App Store Connect 网页 = 提审 + 上架**

---

## 十二、你当前最小可行执行方案

如果你现在就想尽快跑通一次，最少做这些：

1. 准备 `IOS_BUNDLE_ID`
2. 准备 `IOS_TEAM_ID`
3. 准备 `Apple Distribution` 类型 `.p12`
4. 准备 `App Store` 类型 `.mobileprovision`
5. 准备 `Issuer ID`、`Key ID`、`.p8`
6. 全部填到 GitHub Secrets
7. 运行：
   - `release_mode=testflight_internal_only`
   - `internal_testflight_groups=Internal QA`
8. 等 GitHub 构建并上传
9. 去 TestFlight 看 build

---

## 十三、常见错误对照

### 错误：缺少 GitHub Secret

原因：某个 Secret 没填。

处理：去 GitHub `Settings -> Secrets and variables -> Actions` 补上。

### 错误：Bundle ID 不合法

原因：`IOS_BUNDLE_ID` 含下划线或格式错误。

处理：改成类似：

```text
com.fzy.pangbao
```

### 错误：签名失败

原因通常是以下四个不匹配：

- 证书类型
- 描述文件类型
- Bundle ID
- Team ID

### 错误：上传 TestFlight 失败

优先检查：

- `Issuer ID`

### 错误：Internal Only 模式提示缺少组配置

原因：`release_mode=testflight_internal_only` 但未填写 `internal_testflight_groups`。

处理：在 `Run workflow` 时补充组名（可逗号分隔多个组），例如 `Internal QA,Core Team`。

### 错误：上传成功但内部分配失败

原因可能是组名不匹配、API 权限不足，或 Apple 处理构建尚未完成。

处理：

1. 先去 App Store Connect -> TestFlight 检查 build 是否已处理完成
2. 手工分配到目标 Internal Testing 组
3. 核对 `internal_testflight_groups` 与后台组名是否一致
- `Key ID`
- `.p8` 是否正确
- App Store Connect 里是否已经创建过这个 App

---

## 十四、建议你现在就准备的材料清单

你可以直接照这个 checklist 去收集：

- [ ] `IOS_BUNDLE_ID`
- [ ] `IOS_TEAM_ID`
- [ ] `Apple Distribution` 证书 `.p12`
- [ ] `.p12` 密码
- [ ] `App Store` 类型 `.mobileprovision`
- [ ] `Issuer ID`
- [ ] `Key ID`
- [ ] `.p8`
- [ ] GitHub 仓库管理员权限（能写 Secrets）

---

## 十五、你现在最值得做的下一步

如果你要最快跑通：

1. 先去 Apple 后台拿到 `Bundle ID` 和 `Team ID`
2. 找到或导出 `.p12`
3. 下载 `.mobileprovision`
4. 创建 App Store Connect API Key 拿到 `.p8`
5. 把它们全部填进 GitHub Secrets
6. 运行一次 `Build iOS IPA`
