# 胖宝（`pangbao_app`）

**所有 `flutter` / `dart` 命令（如 `flutter run`、`flutter pub get`）必须在包含 `pubspec.yaml` 的目录执行，即本仓库的 `app/` 目录；在仓库根目录 `flutter_ai_talk/` 下运行会报 `No pubspec.yaml file found`。**

OpenSpec 变更：`openspec/changes/cold-start-fast-splash`（冷启动品牌 Splash、移除 Vosk 减包体）、`openspec/changes/pangbao-app`（M1）、`openspec/changes/pangbao-m2-editing-trends`（编辑/历史/趋势增强）、`openspec/changes/pangbao-web-input-mode`（Web 主输入文字/语音可配置）、`openspec/changes/pangbao-api-liantiao`（后端接口联调）、`openspec/changes/app-wechat-sdk-login`（微信 SDK / 网页授权）、`openspec/changes/pangbao-device-login-apk-install`（胖宝号默认登录、Android 缓存安装）、`openspec/changes/api-json-camelcase-fields`（网关 JSON camelCase 约定与实现）、`openspec/changes/device-login-baby-save-user-save`（胖宝号会话保存宝宝资料走 `user/save`）、`openspec/changes/feed-history-ws-after-chat`（发消息后依赖 WS 更新历史、WS 未就绪禁发 chat）、`openspec/changes/history-detail-editable-fields`（历史详情按 `eventNumber` 编辑时间与用量、备注；删除：`POST /device/history/api/event/delete`，body `id`、`deviceNo`）。

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

### 语音识别（设置中心）

- **Android 默认「云端实时转写」**（`WS_VOICE_ASR_URL` 或基址推导的 `/voice/asr/ws`）；**iOS 默认「系统语音识别」**。
- 设置中可在 **云端识别** 与 **系统识别** 之间切换；云端断开时主页麦克风区会提示「语音转写未连接」。
- 无网时可使用文字输入；系统 STT 是否可用取决于设备（如部分 Android 无 Google 语音服务时需改用云端或文字）。

## 打包与发布（Android / iOS / Web）

以下命令均在 **`app/`** 目录执行（与上文一致）。

### Android

- **调试 APK**（体积大、未混淆，便于内测）：

```bash
cd app
flutter build apk --debug
# 产物：build/app/outputs/flutter-apk/app-debug.apk
```

- **发布 APK**（单架构可减小体积，示例 arm64）：

```bash
cd app
flutter build apk --release --target-platform android-arm64
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

- **Google Play 上架用 AAB**（推荐）：

```bash
cd app
flutter build appbundle --release
# 产物：build/app/outputs/bundle/release/app-release.aab
```

**签名**：正式发布需在 `android/app/build.gradle` 中配置 `signingConfigs`（密钥库 `.jks` / `.keystore` 勿提交仓库）。细则见 [官方文档：为应用签名](https://docs.flutter.dev/deployment/android#signing-the-app)。

### iOS

在 **macOS + 已安装 Xcode** 的 `app/` 目录：

```bash
cd app
flutter build ipa --release
# 或先 flutter build ios，再用 Xcode 打开 ios/Runner.xcworkspace → Product → Archive
```

产物与上传 TestFlight / App Store Connect 的流程以 Apple 文档为准；需正确配置 **Bundle ID**、**签名与描述文件**、**Capabilities**（如 Universal Links 与微信相关能力）。

- **无 Mac 方案**：仓库已提供 GitHub Actions 远程打包配置，可在 GitHub 的 macOS Runner 上生成 `.ipa`；说明见 `../docs/github-ios-ipa.md`。

### Web：本地构建

本工程 Web 使用 **`PathUrlStrategy`**（路径形如 `/settings`，无 `#`），部署时服务端需把「未知路径」回退到 `index.html`，否则刷新子路由会 404。

```bash
cd app
flutter build web --release
```

- **产物目录**：`app/build/web/`（需整目录上传，含 `index.html`、`main.dart.js`、`assets/`、`canvaskit/`（若使用默认渲染器）等）。
- **生产环境 API 等**：与 `flutter run` 相同，通过 **`--dart-define=...`** 注入，例如：

```bash
flutter build web --release ^
  --dart-define=API_BASE_URL=https://你的网关域名 ^
  --dart-define=WS_HISTORY_URL=wss://你的网关域名/device/app/ws/history
```

（**CMD** 用 `^` 续行；**PowerShell** 用反引号 `` ` `` 续行，或整段写成一行。）

- **若站点不在域名根路径**（例如 `https://example.com/pangbao/`），必须加 **`--base-href=/pangbao/`**（末尾保留 `/`），且 Nginx 的 `location` 与静态根路径要与之一致。

### Web：发布到你的云服务器（重点）

思路：**本机或 CI 执行 `flutter build web`** → 把 **`build/web/` 下全部文件** 同步到云机 Web 根目录 → 用 **Nginx（或 Caddy、Apache）** 提供静态文件并做 SPA 回退。

#### 1. 同步文件到服务器

任选其一（将 `用户`、`服务器IP`、`远端目录` 换成你的）：

- **rsync**（Linux / macOS，或 Windows 安装 OpenSSH 后可用）：

```bash
cd app
rsync -avz --delete build/web/ 用户@服务器IP:/var/www/pangbao/
```

`--delete` 会删除远端已不存在于本地的文件，避免旧版本 `main.dart.js` 残留；若不想删远端多余文件可去掉 `--delete`。

- **scp**（递归拷贝整个目录）：

```bash
cd app
scp -r build/web/* 用户@服务器IP:/var/www/pangbao/
```

首次建议在服务器上 **`mkdir -p /var/www/pangbao`** 并 **`chown`** 给 SSH 用户可写。

#### 2. Nginx 最小示例

站点根目录指向上传后的目录（与 `root` 一致）；**`try_files`** 保证 Flutter Web 路由刷新可用：

```nginx
server {
    listen 80;
    server_name 你的域名;

    root /var/www/pangbao;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 可选：为带 hash 的静态资源设长缓存（按实际文件名调整）
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

重载 Nginx：`sudo nginx -t && sudo systemctl reload nginx`。

- **HTTPS**：在服务器上用 **Let’s Encrypt（certbot）** 等为 `server_name` 申请证书，或云厂商「SSL 证书」绑定到负载均衡；生产环境建议 **全站 HTTPS**，且 **`API_BASE_URL` / `WS_HISTORY_URL` 使用 https/wss**，避免浏览器 **mixed content** 拦截 HTTP 接口。

#### 3. 与后端联调注意

- **CORS**：上线后页面 `Origin` 变为 `https://你的域名`，网关必须在响应中允许该来源（参见上文「Web 与跨域」），否则浏览器仍会拦截 API。
- **`--dart-define`**：构建时写死的常量会打进前端包，更换网关地址需 **重新 build 并重新上传** `build/web/`。

### Web：云服务器 Docker（本地无 Docker / 在云上构建）

适用：**本机 Docker 不可用**，把代码同步到云主机后，在 **服务器上** 用 Docker 完成 `flutter build web` 并跑一个带 Nginx 的容器（无需在服务器单独安装 Flutter SDK）。

仓库已提供：

- `app/Dockerfile`：多阶段构建（**`debian:bookworm-slim` 内自装 Flutter SDK** → `nginx:alpine`；避免部分环境使用 `cirruslabs/flutter` 时出现 `unable to find user root`）
- `app/docker/nginx-flutter.conf`：静态资源 + `try_files` 回退 `index.html`（适配 PathUrlStrategy）
- `app/docker-compose.yml`：Compose 构建并运行（镜像 **`pangbao-web:latest`**，容器 **`pangbao-web`**，默认 **8080→80**）
- `app/.env.example`：复制为 **`.env`** 后填写网关等变量；与 **`--env-file`** 配合使用（`.env` 勿提交）

#### 1. 把代码弄到服务器

任选：`git clone` 后进入本仓库的 **`app/`** 目录（与 `pubspec.yaml` 同级），或用 `rsync`/`scp` 同步整个仓库（至少包含 **`app/`** 下源码与 `pubspec.lock`）。

#### 2. 推荐：在 `app/` 目录用 docker compose

**路径是相对「当前工作目录」解析的。** 若在 **`app/`** 下执行，**不能**写 `app/.env.example`、`app/docker-compose.yml`（会变成 `app/app/...`，文件不存在）。

在 **`app/`** 下请使用：

```bash
cd /www/wwwroot/flutter/flutter_ai_talk/app/ 
# cp .env.example .env
# 编辑 .env（或继续用 .env.example 作模板时把下面 --env-file 指到对应文件）
docker compose --env-file .env.example -f docker-compose.yml up -d --build
```

上线时把 **`--env-file .env.example`** 换成 **`--env-file .env`**，并在 `.env` 中填写真实 **`API_BASE_URL`** / **`WS_HISTORY_URL`** 等。

**`--env-file` 的作用**：只负责把文件里的变量代入 `docker-compose.yml` 里的 **`${…}`**（含 `build.args`），从而在 **构建镜像** 时传给 Dockerfile；**不会**默认写进运行中容器进程（静态 Web 的网关地址已在编译时打进前端）。改环境后需带 **`--build`** 才会重新构建。

浏览器访问 **`http://服务器IP:8080`**（或 `.env` 里 **`WEB_PORT`**）。未设置 **`API_BASE_URL`** 时与未传 dart-define 的 release 一致，使用 `env.dart` 默认基址。

**子路径**：在 env 文件中设 **`BASE_HREF=/pangbao/`**（**末尾 /**），并配置反代。

**若在仓库根目录**（`flutter_ai_talk/` 与 `app/` 同级）执行、且希望路径里带 **`app/`** 前缀，可用：

```bash
docker compose --env-file app/.env.example -f app/docker-compose.yml up -d --build
```

（此时 `--env-file` 指向 **`app/.env.example`**，`-f` 指向 **`app/docker-compose.yml`**。）

**更新发版**：在所用目录再次执行同一条 compose 命令（带 **`--build`**）。**停止容器**：`docker compose -f … down`（在 **`app/`** 下可省略 `-f`）。

#### 3. 等价方式：`docker build` + `docker run`（不用 Compose 时）

在 **`app/`** 目录：

```bash
cd app
docker build -t pangbao-web \
  --build-arg API_BASE_URL=https://你的网关域名 \
  --build-arg WS_HISTORY_URL=wss://你的网关域名/device/app/ws/history \
  .
docker run -d --name pangbao-web -p 8080:80 --restart unless-stopped pangbao-web
```

若已用 Compose 起过同名容器，先 **`docker rm -f pangbao-web`** 再 `docker run`，或统一只用 Compose。

#### 4. 架构与资源说明（Docker）

- **首次构建**会拉取 **Debian**、clone Flutter、`precache --web` 与编译；**Dockerfile 已默认使用阿里云 apt 源与 Flutter 中国镜像**（`pub.flutter-io.cn` / `storage.flutter-io.cn`，Flutter SDK 默认从 Gitee 镜像 clone）。层缓存命中后会快很多。建议云主机 **≥2GB 内存**。
- 云主机为 **ARM**（如部分云 ARM 规格）时，若在 **x86** 机器上交叉构建，可加 `docker build --platform linux/arm64 ...`；镜像与目标机 CPU 需一致或由 Docker 做 qemu（较慢，优先在同架构机上构建）。
- 对外正式域名、HTTPS 仍建议在容器前加 **云负载均衡 / Nginx / Caddy** 终止 TLS，再反代到 `8080`；**CORS / mixed content** 要求与上文「与后端联调注意」「Web 与跨域」相同。

**构建失败：`unable to find user root: invalid argument`**：常见于宿主机 **runc/containerd** 与某些 **第三方 Flutter 基础镜像**不兼容。本仓库 Dockerfile 已改为在 **Debian** 中自装 Flutter；若仍失败，再升级 **`docker-ce`、`containerd.io`**，或先关 BuildKit：`DOCKER_BUILDKIT=0 docker compose … build` / `DOCKER_BUILDKIT=0 docker build -t pangbao-web .`；仍失败请附上 `docker version` 与 `docker build --progress=plain …` 日志。

**构建仍很慢时**：确认未并行重复执行多次 `up --build`；第二次构建应命中 Docker 层缓存。若 Gitee Flutter 镜像异常，可构建时加 **`--build-arg FLUTTER_GIT_URL=https://github.com/flutter/flutter.git`**。若 `apt` 报证书错误，Dockerfile 已用 **`http://mirrors.aliyun.com`** 引导安装 `ca-certificates`（勿把 apt 源改成 https 直到包装好证书）。长期仍建议在本机/CI 构建镜像或 `build/web`，线上只拉镜像或同步静态文件。

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

### 登录（仅微信）

- **当前方式**：登录页仅提供 **微信登录** 入口；客户端通过微信授权获取临时 code，再请求 **`POST /device/app/api/login`** 建立会话。
- **Web**：若已配置 `WECHAT_WEB_APP_ID` / `WECHAT_OAUTH_REDIRECT_URI`，点击登录会跳转到微信网页授权；回调返回 `/auth/wechat/callback` 后会继续登录流程，不再提示改用胖宝号登录。
- **开发联调**：`WX_LOGIN_CODE` 仍可作为开发兜底，供未接通真微信环境时验证登录链路；它不是用户可见主流程。
- **BREAKING**：客户端已移除胖宝号（设备号）登录入口，不再通过页面交互触发 **`POST /device/app/api/device_login`**。

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

### 网关相对资源路径（logo、APK 等）

- 服务端可将 **`logo`**（事件目录）、**`downloadUrl`**（版本检查）等返回为**去掉域名的路径**，例如 `/ai_talk_images/event_1.png`、`/device/app/apk/foo.apk`。
- 客户端通过 `lib/api/gateway_absolute_url.dart` 的 **`resolveGatewayAbsoluteUrl`**，与 HTTP 请求相同的基址 **`API_BASE_URL`**（`AppEnv.apiBaseUrl`）拼接为可下载/可展示的绝对 URL；若已是 `http://` 或 `https://` 则原样使用。

### 微信登录（fluwx + 网页 OAuth）

1. **勿提交 AppSecret**；客户端仅需 AppId、回调域名等公开配置。  
2. **Android**：`fluwx` 已通过插件 `AndroidManifest` 合并 `WXEntryActivity` 与 `queries`（微信包名 `com.tencent.mm`）；请保证应用包名与签名与开放平台「移动应用」登记一致。  
3. **iOS**：将 `pubspec.yaml` 中 `fluwx.app_id`、`fluwx.ios.universal_link` 替换为真实值，与 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 及 `apple-app-site-association` 一致。  
4. **Web**：使用 `PathUrlStrategy`（见 `main.dart`）；在开放平台登记网站应用，**授权回调域**与 `WECHAT_OAUTH_REDIRECT_URI` 完全一致（路径为 `/auth/wechat/callback`）。本地示例：`http://localhost:xxxx/auth/wechat/callback`（端口与 `flutter run` 一致）。  
5. **运行示例**（登录页会直接调用微信登录；`WX_LOGIN_CODE` 仅用于开发联调兜底）：

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
- **微信**：网关仍以 **`jsCode`** 接收临时 code；当前产品登录页直接走微信登录，联调可额外使用 `WX_LOGIN_CODE` 兜底。
- **主页聊天与历史 WebSocket**：
  - 进入首页仍会 **`GET /device/history/api/list`** 拉一次初始列表。
  - 须配置 **`WS_HISTORY_URL`**（或通过 `API_BASE_URL` 自动推导 ws 地址）。历史 WebSocket 建连并收到服务端 **`auth_ok`** 之前，客户端 **不会** 调用 `POST /device/history/api/chat`；未就绪时会有 Toast，可在首页 AppBar 使用 **云形图标「重连历史」** 手动重连。
  - `chat` 成功后 **不再** 自动请求 list；列表增量依赖服务端经 WebSocket 推送的 `create`/`update`/`delete` 等事件（需网关保证 `chat` 完成后有对应推送）。

### 真机 / 浏览器冒烟（需本地执行）

- **登录**：在 Android / iOS / Web（若已配置网页授权）完成一次微信登录并进入主页；取消授权或缺少配置时应得到明确提示而非设备号引导。
- **Android 更新**：在能访问版本接口与 APK 下载 URL 的环境下，从更新弹窗执行「下载并安装」；若系统拦截，按提示到 **设置 → 允许安装未知应用 / 来自此来源的应用**（华为、小米、OPPO、vivo 等路径略有差异）授权后重试。
- **历史微信流程**（若重新开放 UI）：在 Android、iOS 真机与 HTTPS 测试域 Web 各完成一次：打开微信 → 授权 → 回到应用 → 进入主页；取消授权时应有 Toast 且应用不崩溃。详细任务见 `openspec/changes/app-wechat-sdk-login/tasks.md`。

## 交互说明（M2）

- **主页历史列表**：每条为富文本摘要；点击一行在主页底部弹出 **编辑 Sheet**，可滚轮调整时分（不改日期）、编辑备注/用量、停止计时或删除，保存走 `POST /device/history/api/event/update`。更新请求体中 **`startTime` / `endTime` 为 Unix 秒级整型时间戳**（与列表解析一致，非毫秒）。`pending:*` 乐观记录在同步完成前为只读。
- **Web 主输入**：默认 **单行** 输入框，**Enter** 或「提交」走 `POST /device/history/api/chat`。通过 `WEB_HOME_INPUT=voice`（或改 `kDefaultWebHomeInputMode`）可改为按住说话；识别不可用时自动回到文字并提示。
- **趋势中心**：先拉取服务端事件目录，**下拉单选**某一事件后加载 `piece`；展示 **折线 + 量柱**（同一标量：计时类 `eventNumber==0` 为持续**小时数**，否则为次数）。时间范围仍为今日/周/月/季。

## 已知限制

- **Web 隐私页**：`PolicyScreen` 在 Web 上以占位文本为主（`webview_flutter` 能力因浏览器而异）。
- **Web 刷新**：通过条件导入 `dart:html` 触发 `location.reload()`。
- **Android 应用内安装**：发现新版本后，Android 将 APK **下载到应用缓存目录**（`path_provider` 临时目录下 `apk_updates/`），经 **FileProvider** 调起系统安装器；Manifest 已声明 `REQUEST_INSTALL_PACKAGES`。若 `canRequestPackageInstalls` 为 false，会跳转系统「安装未知应用」相关设置页，用户授权后需在应用内重新触发下载/安装。

## 目录说明

- `lib/`：应用源码（路由、页面、HTTP/WebSocket 仓库、主题）。
- `android/` / `web/`：平台工程（Android 需 `local.properties`）。
- `Dockerfile`、`docker-compose.yml`、`.env.example`：云端 Docker / Compose（见「Web：云服务器 Docker」）。
- `docker/nginx-flutter.conf`：容器内 Nginx 的 SPA 回退配置。
