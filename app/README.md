# 胖宝（`pangbao_app`）

**所有 `flutter` / `dart` 命令（如 `flutter run`、`flutter pub get`）必须在包含 `pubspec.yaml` 的目录执行，即本仓库的 `app/` 目录；在仓库根目录 `flutter_ai_talk/` 下运行会报 `No pubspec.yaml file found`。**

OpenSpec 变更：`openspec/changes/pangbao-app`（M1）、`openspec/changes/pangbao-m2-editing-trends`（编辑/历史/趋势增强）、`openspec/changes/pangbao-web-input-mode`（Web 主输入文字/语音可配置）、`openspec/changes/pangbao-api-liantiao`（后端接口联调）、`openspec/changes/app-wechat-sdk-login`（微信 SDK / 网页授权）、`openspec/changes/pangbao-device-login-apk-install`（胖宝号默认登录、Android 缓存安装）、`openspec/changes/api-json-camelcase-fields`（网关 JSON camelCase 约定与实现）、`openspec/changes/device-login-baby-save-user-save`（胖宝号会话保存宝宝资料走 `user/save`）。

## 环境要求

- Flutter SDK（建议稳定版 3.24+，需已配置 `flutter` / `dart` 到 PATH）
- Android Studio / Xcode（按需）

## 首次运行前

1. 在 `app/android/` 下创建 `local.properties`，填入本机 Flutter SDK 路径（可参考 `local.properties.example`）。
2. 在项目根执行：

```bash
cd app
flutter pub get
flutter run -d chrome
# 或
flutter run -d android
```

> 若缺少 iOS 工程目录，可在已安装 Xcode 的机器上执行：`flutter create . --platforms=ios`（会补齐模板文件；注意与现有 `pubspec.yaml` 合并）。

## Web 与跨域（CORS）

`flutter run -d chrome` 时，页面源为 **`http://localhost:<随机端口>`**，而默认 `API_BASE_URL` 指向 **`http://www.cuplay.top:9702`**（或其它域名）。浏览器会按 **同源策略** 拦截跨域请求：能否发成功取决于 **服务端是否在响应里带上正确的 CORS 头**（例如 `Access-Control-Allow-Origin`，以及对 `OPTIONS` 预检的 `Access-Control-Allow-Methods` / `Allow-Headers` 等）。**Flutter / `http` 包无法在应用里“关掉”浏览器的 CORS**，这不是客户端 bug。

**推荐（正确做法）**：在网关或反向代理（Nginx、Spring `WebMvcConfigurer` 等）为联调环境增加 CORS，至少允许：

- `Origin`: `http://localhost:*`（或你本机固定端口），以及日后正式 Web 域名；
- 常用方法：`GET`、`POST`、`OPTIONS`；
- 常用请求头：`Content-Type`、`Authorization`（若使用）。

改完后在 Chrome **开发者工具 → Network** 里看失败请求：若控制台有 `blocked by CORS policy`，即为未放行当前 `Origin`。

**仅本地开发（不安全，勿用于日常上网）**：可临时用无安全策略的 Chrome  profile 启动，便于在后端尚未配 CORS 时自测：

```bash
cd app
flutter run -d chrome --dart-define=MOCK_NEWER_VERSION=true --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/temp/flutter_chrome_cors_dev"
```

（PowerShell 可直接一行粘贴；CMD 可用 `^` 换行。）请先创建目录 `C:/temp/flutter_chrome_cors_dev`（路径可改）。**不要用你日常 Chrome 的默认用户目录**，且联调结束应关掉该实例。

**其它**：若将来 Web 页是 **HTTPS** 而 API 仍是 **HTTP**，还会触发 **mixed content** 被拦截，需 API 也走 HTTPS 或由同源代理转发。

## `--dart-define`（勿把真实密钥写入仓库）

| 变量 | 说明 |
|------|------|
| `PRIVACY_POLICY_URL` | 隐私政策页面 URL（默认 example.com） |
| `API_BASE_URL` | 后端基址（默认 `http://www.cuplay.top:9702`） |
| `WX_LOGIN_CODE` | 无移动 SDK / 无网页授权配置时的联调临时 code，作为登录请求体字段 **`jsCode`** 提交 |
| `WECHAT_APP_ID` | 微信开放平台**移动应用** AppId（`fluwx.registerApi`）；与 `pubspec.yaml` 中 `fluwx.app_id` 保持一致 |
| `WECHAT_UNIVERSAL_LINK` | iOS Universal Links 前缀（须与开放平台、`pubspec.yaml` → `fluwx.ios.universal_link` 一致） |
| `WECHAT_WEB_APP_ID` | **网站应用** AppId；留空则网页授权使用 `WECHAT_APP_ID` |
| `WECHAT_OAUTH_REDIRECT_URI` | 网页授权回调完整 URL，须登记为 `…/auth/wechat/callback`（与路由一致） |
| `WS_HISTORY_URL` | 历史 WebSocket **完整 URL**；**留空**时根据 `API_BASE_URL` 自动推导 `ws(s)://…/device/app/ws/history` |
| `REFRESH_TOKEN_PATH` | 静默刷新 access token 的 POST path（相对 [apiBaseUrl]）；请求体字段 **`refreshToken`**；设为空字符串可关闭 |
| `IOS_APP_STORE_ID` | App Store 数字 ID（占位） |
| `MOCK_NEWER_VERSION` | `true` 时强制出现「发现新版本」提示（联调 UI） |
| `WEB_HOME_INPUT` | Web 主页主输入：`text`（默认）或 `voice`（按住说话 + STT，与移动端一致；失败时自动降级为文字） |

示例：

```bash
flutter run --dart-define=MOCK_NEWER_VERSION=true --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy
```

Web 语音主输入（Chrome 等需允许麦克风；本地 `localhost` 通常可用）：

```bash
cd app
flutter run -d chrome --dart-define=WEB_HOME_INPUT=voice
```

也可修改源码中的默认：`lib/config/web_home_input_mode.dart` 内常量 `kDefaultWebHomeInputMode`（未传 `WEB_HOME_INPUT` 时生效）。

### 登录（默认胖宝号）

- **默认方式**：登录页主流程为 **胖宝号登录**（输入网关下发的设备号），请求 **`POST /device/app/api/device_login`**，JSON body 字段 **`deviceNo`**（lowerCamelCase）。成功后与会话、设备号缓存逻辑与历史微信登录一致。
- **微信登录**：入口仍展示，点击仅提示 **「当前功能未开放」**，不拉起微信、不请求 `POST /device/app/api/login`。
- **Web**：若浏览器中残留历史网页 OAuth 的 `sessionStorage` 授权码，进入登录页时会清除并提示使用胖宝号登录，**不会**自动走微信网关登录。

### 宝宝画像（读 / 写）

- **读取**：`GET /device/app/api/user/get`，query **`deviceNo`**；响应用于生日、性别等（与本地昵称合并后写 prefs）。
- **保存（设置页「保存」）**：
  - 当前会话为 **胖宝号登录**（本地持久化渠道 `device`）时：`POST /device/app/api/user/save`，JSON body 含 **`deviceNo`**、**`birthday`**（Unix 秒）、**`sex`**、**`nickname`**（camelCase；若网关字段名不同需与后端对齐）。
  - 渠道为 **微信** 或 **未知**（旧安装未写入渠道）：仍使用 **`POST /device/app/api/user/auto_save`**（仅 `birthday`、`sex`）。
- **创建新宝宝**（绑定页「创建并绑定」）：仍仅调用 **`POST /device/app/api/user/auto_save`**，不受上述保存分支影响。
- **联调说明**：`user/save` 的正式契约（字段必填子集、响应是否含 `deviceNo`）以网关文档为准；README 描述为客户端当前实现假设。

### 网关 JSON 字段命名（lowerCamelCase）

- **约定**：HTTP/WebSocket 业务 JSON 键名使用 **lowerCamelCase**（如 `deviceNo`、`accessToken`、`refreshToken`、`downloadUrl`、`jsCode`）。客户端出站已按此发送；历史 WebSocket 鉴权首帧使用 **`accessToken`**（不再使用 `access_token` 作为正式键名）。
- **入站兼容**：解析响应时通过 `lib/api/gateway_json.dart` 的 `readGatewayStr` **优先 camel、再回退 snake**，直至网关确认不再返回 snake 后可删除回退（见 `openspec/changes/api-json-camelcase-fields`）。
- **后端对齐**：若网关仍只接受旧 snake 请求体或 WS 只认 `access_token`，需后端增加 camel 别名或同步升级，否则联调会失败。

### 微信登录（fluwx + 网页 OAuth，当前产品入口已关闭）

1. **勿提交 AppSecret**；客户端仅需 AppId、回调域名等公开配置。  
2. **Android**：`fluwx` 已通过插件 `AndroidManifest` 合并 `WXEntryActivity` 与 `queries`（微信包名 `com.tencent.mm`）；请保证应用包名与签名与开放平台「移动应用」登记一致。  
3. **iOS**：将 `pubspec.yaml` 中 `fluwx.app_id`、`fluwx.ios.universal_link` 替换为真实值，与 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 及 `apple-app-site-association` 一致。  
4. **Web**：使用 `PathUrlStrategy`（见 `main.dart`）；在开放平台登记网站应用，**授权回调域**与 `WECHAT_OAUTH_REDIRECT_URI` 完全一致（路径为 `/auth/wechat/callback`）。本地示例：`http://localhost:xxxx/auth/wechat/callback`（端口与 `flutter run` 一致）。  
5. **运行示例**（联调网关微信登录代码路径时仍可用 `RemoteAuthRepository.signInWithWeChat`，但 UI 已不调用）：

```bash
cd app
flutter run -d android --dart-define=WECHAT_APP_ID=wx你的移动应用AppId
flutter run -d chrome --dart-define=WECHAT_APP_ID=wx你的AppId --dart-define=WECHAT_OAUTH_REDIRECT_URI=http://localhost:8080/auth/wechat/callback
```

### 接口联调（网关）

```bash
cd app
flutter run -d chrome --dart-define=WX_LOGIN_CODE=你的微信code
flutter run -d chrome --dart-define=WX_LOGIN_CODE=xxx --dart-define=WS_HISTORY_URL=ws://www.cuplay.top:9702/device/app/ws/history
```

- 未登录也可进主页；历史为空会出现 **「请绑定宝宝信息」** 条，点击未登录去登录、已登录去 **`/settings/bind-baby`**。
- 业务 `code != 0` 时通过 `apiToastProvider` 提示 `message`。
- **微信**：网关仍以 **`jsCode`** 接收临时 code；当前产品登录页已关闭微信入口，联调可用 `WX_LOGIN_CODE` 或代码内直接调用仓库方法。

### 真机 / 浏览器冒烟（需本地执行）

- **登录**：使用胖宝号完成一次登录并进入主页；点击「微信登录」应仅出现「当前功能未开放」。
- **Android 更新**：在能访问版本接口与 APK 下载 URL 的环境下，从更新弹窗执行「下载并安装」；若系统拦截，按提示到 **设置 → 允许安装未知应用 / 来自此来源的应用**（华为、小米、OPPO、vivo 等路径略有差异）授权后重试。
- **历史微信流程**（若重新开放 UI）：在 Android、iOS 真机与 HTTPS 测试域 Web 各完成一次：打开微信 → 授权 → 回到应用 → 进入主页；取消授权时应有 Toast 且应用不崩溃。详细任务见 `openspec/changes/app-wechat-sdk-login/tasks.md`。

## 交互说明（M2）

- **主页历史列表**：每条展示为 **`事件名:动作`**；点击一行进入 **历史详情** 可编辑并 `POST /device/history/api/event/update` 保存。
- **Web 主输入**：默认 **单行** 输入框，**Enter** 或「提交」走 `POST /device/history/api/chat`。通过 `WEB_HOME_INPUT=voice`（或改 `kDefaultWebHomeInputMode`）可改为按住说话；识别不可用时自动回到文字并提示。
- **趋势中心**：支持 **今日 / 周 / 月 / 季**；图表带 **横轴日期（MM-dd）** 与 **纵轴数值**。

## 已知限制

- **Web 隐私页**：`PolicyScreen` 在 Web 上以占位文本为主（`webview_flutter` 能力因浏览器而异）。
- **Web 刷新**：通过条件导入 `dart:html` 触发 `location.reload()`。
- **Android 应用内安装**：发现新版本后，Android 将 APK **下载到应用缓存目录**（`path_provider` 临时目录下 `apk_updates/`），经 **FileProvider** 调起系统安装器；Manifest 已声明 `REQUEST_INSTALL_PACKAGES`。若 `canRequestPackageInstalls` 为 false，会跳转系统「安装未知应用」相关设置页，用户授权后需在应用内重新触发下载/安装。

## 目录说明

- `lib/`：应用源码（路由、页面、HTTP/WebSocket 仓库、主题）。
- `android/` / `web/`：平台工程（Android 需 `local.properties`）。
