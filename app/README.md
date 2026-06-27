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
flutter run -d chrome  --dart-define=API_BASE_URL=http://localhost:9702 
# 或
flutter run -d android
```

> 若缺少 iOS 工程目录，可在已安装 Xcode 的机器上执行：`flutter create . --platforms=ios`（会补齐模板文件；注意与现有 `pubspec.yaml` 合并）。

### Debug 日志

Debug 构建下，Dart 侧 console 使用 **白名单 tag**（含 ISO8601 时间戳）：

| Tag | 用途 |
|-----|------|
| `[ApiHttp]` | `ApiClient` HTTP 请求/响应（敏感字段已脱敏） |
| `[UcgFeed]` | 广场 Feed 加载/下拉刷新各阶段耗时 |
| `[UcgLocation]` | UCG 坐标 consent / 缓存命中 / GPS 刷新 |
| `[UcgVideo]` | 本地视频 ffmpeg normalize / v2 上传 |
| `[UcgVideo]` | 本地视频 ffmpeg normalize / v2 上传 |

`app/lib` 内不使用其它零散 `debugPrint`（无 `HomeHistoryLog`、WS 调试等）。

`flutter run` 终端仍会转发设备 **完整 logcat**，其中可能混入：

| 来源 | 示例 | 能否在仓库内关闭 |
|------|------|------------------|
| 白名单 tag | `I/flutter: [UcgFeed] 2026-… onRefresh fired` | 即目标日志 |
| 微信 Open SDK（fluwx） | SDK 原生日志 | `pubspec.yaml` 中 `fluwx.debug_logging: false`（默认） |
| vivo / 其它 OEM | `D/ScreenUtils: hasVivoFreeformTasks` | **否**（ROM 或三方 AAR，非 Dart 代码） |
| 系统 / 引擎 | `ActivityThread`、`Open vivo delay for GC JIT` | **否** |

**推荐：单独终端只看白名单日志**

终端 A 照常运行应用：

```bash
cd app
flutter run -d android --dart-define=API_BASE_URL=https://test.pangbao.cuplay.top
```

终端 B（Windows，需 `adb` 在 PATH；**推荐用脚本**，避免 PowerShell 管道 GBK 导致 JSON 中文乱码）：

```powershell
cd app
.\scripts\logcat_api_http.ps1
```

脚本顶部 `$Tags` 数组可增删 tag。若需手动过滤，请先 `chcp 65001`，或使用 PowerShell 7+（`pwsh`）。

```powershell
adb logcat -s flutter | Select-String '\[ApiHttp\]|\[UcgFeed\]|\[UcgLocation\]'
```

**下拉刷新排查**：在终端 B 对齐 `[UcgFeed] onRefresh fired` → `fetchRecommendedFeed calling` → `[ApiHttp] -> GET …/feed/recommend` 的时间戳，可拆分「触发刷新 → 发 HTTP」各段耗时。

临时排查微信 SDK 问题时，可将 `pubspec.yaml` 的 `fluwx.debug_logging` 改回 `true` 后重新 `flutter pub get`。

### UCG 本地视频上传（normalize）

- **统一入口**：所有本地视频 OSS 上传 MUST 经 `ucgUploadLocalVideo`（compose、聊天、历史同步、相册直传）。
- **iOS/Android**：每条本地视频经 `ffmpeg_kit_flutter_new_min_gpl` 转码为 H.264 Main + AAC（无音轨补静音）+ `-movflags +faststart`，`transform_version` **`v2`**；不再因 ≤20MB 跳过转码。
- **Web**：校验后直传 raw（`transform_version` **`v1`**），不使用 ffmpeg.wasm；canonical MP4 由 **go_ai_talk 服务端 ffmpeg worker** 异步补齐（Phase 2，本仓库不实现）。
- **APK 体积**：`ffmpeg_kit_flutter_new_min_gpl` 约增加数 MB/ABI（min-gpl 变体）；Play 分发建议 `.aab`。
- **播放兜底**：CDN/内联 `VideoPlayer` 失败时 UI 提供「用系统播放器打开」（Android `ACTION_VIEW` https；iOS/Web `url_launcher` externalApplication）。

Debug 下 `[UcgVideo]` 日志可确认 normalize 与 v2 上传字节数（见上方 logcat 脚本 `$Tags`）。

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

**签名**：在 `app/android/` 下复制 `key.properties.example` 为 `key.properties`，填入 keystore 路径与密码；将 `.jks` 放在 `app/android/`（二者均已在 `.gitignore` 中）。`build.gradle.kts` 在存在 `key.properties` 时自动启用 release 签名；未配置时使用默认 debug 签名。细则见 [官方文档：为应用签名](https://docs.flutter.dev/deployment/android#signing-the-app)。

#### UCG 启动器角标推送（HMS / MiPush）

社交 UCG 在 **应用被杀进程** 后，通过厂商推送更新启动器数字角标（私信/评论未读）。客户端凭证由 Gradle 在编译期写入 `BuildConfig`（见 `app/android/app/build.gradle.kts`），**勿**用 `--dart-define` 传递。

**范围说明**：仅 **iOS（APNs）**、**华为/荣耀 HMS**、**小米/红米 MiPush** 会注册 push token 并尽量保证杀进程后角标；**其它 Android 厂商**不注册 token，**不保证**启动器数字角标。服务端推送凭证见 `go_ai_talk` 仓库 `manifest/docker/.env.example` 中 `UCG_APNS_*` / `UCG_HMS_*` / `UCG_MIPUSH_*`。

##### 配置 `push.properties`（分步）

**第一步：创建本地配置文件**

在 `app/android/` 目录下复制示例文件：

```bash
cd app/android
cp push.properties.example push.properties
```

（Windows 资源管理器复制粘贴亦可。）`push.properties` 已在 `.gitignore`，**不要提交到 git**。

**第二步：逐项填写字段**

打开 `app/android/push.properties`，按需填写（华为机填 HMS 相关，小米机填 MiPush 相关；可同时填写以便打通用包）：

| 字段 | 含义 | 从哪里获取 |
|------|------|------------|
| `ucg.hms.app_id` | 华为 Push Kit **应用 ID** | [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) → 我的项目 → 选择应用 → **项目设置 → 常规 → 应用 ID**（纯数字）。若已放置 `agconnect-services.json`（见第四步），此项可留空。 |
| `ucg.mipush.app_id` | 小米推送 **AppId** | [小米推送控制台](https://admin.xmpush.xiaomi.com/) → 应用详情页顶部 **AppId** |
| `ucg.mipush.app_key` | 小米推送 **AppKey** | 同上应用详情页 **AppKey** |
| `ucg.mipush.region` | MiPush 服务区域 | 国内应用填 `China`（默认）；海外分发按控制台说明选 `Global` \| `Europe` \| `Russia` \| `India` |

**示例（占位符，请替换为你的真实值）：**

```properties
# 华为 AppGallery Connect 应用 ID
ucg.hms.app_id=123456789012345678
# 小米推送
ucg.mipush.app_id=2882303761512345678
ucg.mipush.app_key=5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ucg.mipush.region=China
```

Gradle 读取逻辑：`build.gradle.kts` 在构建时加载 `app/android/push.properties`，将值注入 `BuildConfig.UCG_HMS_APP_ID`、`UCG_MIPUSH_APP_ID`、`UCG_MIPUSH_APP_KEY`、`UCG_MIPUSH_REGION`。

**第三步：小米还需放置 MiPush SDK（AAR）**

小米推送 SDK **不在 Maven 中央仓库**，须手动下载并放入本地目录：

1. 登录 [小米推送控制台](https://admin.xmpush.xiaomi.com/) → 进入应用 → **SDK 下载**（或文档中的「Android SDK」链接）。
2. 解压后找到 **`MiPush_SDK_Client_*.aar`**（例如 `MiPush_SDK_Client_7_9_2-C_3rd.aar`）。
3. 将该 AAR **复制到** `app/android/app/libs/`（目录内已有 `.gitkeep`；AAR 体积较大，**勿提交 git**）。

Gradle 检测规则（`build.gradle.kts`）：扫描 `app/android/app/libs/` 下文件名 **以 `MiPush_SDK_Client` 开头、以 `.aar` 结尾** 的文件。若 **未检测到** 任何匹配 AAR：

- `BuildConfig.UCG_MIPUSH_ENABLED = false`
- 编译走 `src/nomipush/` 桩代码，MiPush **不会**初始化

检测到 AAR 后才会启用 `src/mipush/` 源码、合并 MiPush `AndroidManifest` 并把 AAR 加入依赖。

**第四步：华为可选 `agconnect-services.json`**

华为 **应用 ID** 有两种填法（二选一即可）：

| 方式 | 操作 |
|------|------|
| A. 仅 `push.properties` | 在 `ucg.hms.app_id=` 填入 AppGallery Connect 应用 ID |
| B. JSON 文件（推荐） | 在 AppGallery Connect **项目设置 → 常规 → 下载 agconnect-services.json**，放到 **`app/android/app/agconnect-services.json`** |

**优先级**：若 `agconnect-services.json` 存在，Gradle 会 **优先** 从 JSON 中解析 `"app_id"` 字段；解析失败或文件不存在时，才回退到 `push.properties` 的 `ucg.hms.app_id`。无需安装 AGConnect Gradle 插件。

`agconnect-services.json` 含项目密钥信息，已在 `.gitignore`，**不要提交到 git**。

**第五步：重新编译**

修改 `push.properties`、MiPush AAR 或 `agconnect-services.json` 后，旧 APK 内的 `BuildConfig` 不会自动更新。建议：

```bash
cd app
flutter clean
flutter run -d android
# 或打 release 包：
flutter build apk --release --target-platform android-arm64
```

**第六步：验证是否生效**

1. **设备要求**：在 **华为/荣耀** 或 **小米/红米** 真机上测试（模拟器通常无法拿到厂商 token）。
2. **登录与绑定**：须 **已登录** 且 UCG 账号 **已绑定微信**（`wxId` 有效）；否则客户端会跳过注册。
3. **通知权限**：Android 13+ 首次启动会请求「通知」权限，需允许。
4. **Logcat / 调试输出**（`flutter run` 终端或 `adb logcat`）：
   - 推送注册无 Dart 侧 debug 日志；请通过网关 **`POST /ucg/app/api/push/register`** 或断点确认是否注册成功
   - 华为：确认 `BuildConfig.UCG_HMS_APP_ID` 非空（app_id 未填则 HMS 不会启动）
   - 小米：确认 `libs/` 内 AAR 存在且 `ucg.mipush.app_id` / `app_key` 已填
5. **网络请求**：登录并绑定微信后，抓包或网关日志应出现 **`POST /ucg/app/api/push/register`**（经 UCG 客户端封装为 `POST /push/register`），请求体示例：

```json
{
  "channel": "hms",
  "token": "…",
  "deviceKey": "…"
}
```

`channel` 在华为/荣耀真机上为 **`hms`**，小米/红米真机上为 **`mipush`**。注册成功后，杀进程状态下服务端推送可更新启动器角标。

**安全提醒**：`push.properties`、`agconnect-services.json`、MiPush AAR、Android 签名 `key.properties` 均为本地机密或二进制依赖，**均勿提交 git**（已在 `app/.gitignore`）。

### iOS

在 **macOS + 已安装 Xcode** 的 `app/` 目录：

```bash
cd app
flutter build ipa --release
# 或先 flutter build ios，再用 Xcode 打开 ios/Runner.xcworkspace → Product → Archive
```

产物与上传 TestFlight / App Store Connect 的流程以 Apple 文档为准；需正确配置 **Bundle ID**、**签名与描述文件**、**Capabilities**（如 Universal Links 与微信相关能力、**Sign in with Apple**）。

**iOS 发布检查清单（`add-apple-sign-in`）：**

- 执行 `bash tool/ci/prepare_ios_project.sh` 后确认 `ios/Runner/Info.plist` 含更新后的 `NSMicrophoneUsageDescription`（含育儿语音示例；可通过 `IOS_MICROPHONE_USAGE_DESCRIPTION` 覆盖）。
- 确认 `ios/Runner/Runner.entitlements` 含 `com.apple.developer.applesignin` = `Default`；Apple Developer App ID 须启用 Sign in with Apple Capability，与描述文件一致。
- CI/IPA 构建前核对 `prepare_ios_project.sh` 已运行；打包后可用 `codesign -d --entitlements -` 抽查 entitlements。

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

`flutter run -d chrome` 时，页面源为 **`http://localhost:<随机端口>`**，而默认 `API_BASE_URL` 指向 **`https://pangbao.cuplay.top`**（或其它域名）。浏览器会按 **同源策略** 拦截跨域请求：能否发成功取决于 **服务端是否在响应里带上正确的 CORS 头**（例如 `Access-Control-Allow-Origin`，以及对 `OPTIONS` 预检的 `Access-Control-Allow-Methods` / `Allow-Headers` 等）。**Flutter / `http` 包无法在应用里“关掉”浏览器的 CORS**，这不是客户端 bug。

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

### UCG 媒体上传（Web）

- **Web**：发帖选图/视频走 **`POST /ucg/app/api/media/upload`**（multipart 经 gateway 同域代理至 ucg-service 再写 OSS），**不再**从浏览器直传 `pang-bao.oss-cn-beijing.aliyuncs.com`，以避免 OSS bucket 未配 CORS 时 `OPTIONS` 预检 403。
- **Android / iOS**：仍走 presign → 客户端 **PUT** 预签名 URL（无浏览器 CORS 限制）。
- **部署**：需 ucg-service 含 `POST /ucg/app/api/media/upload` 且 `config.ucg-service.yaml` 的 `server.clientMaxBodySize` ≥ `25MB`；gateway 反代亦须允许 ≥25MB body。
- **备选（直传 OSS）**：若希望 Web 也走 presign 直传，须在阿里云 OSS 控制台为 bucket `pang-bao` 配置 CORS：允许来源含 `http://localhost:*` 与正式 Web 域名，方法 `PUT`/`GET`/`HEAD`，允许头 `Content-Type`。

## `--dart-define`（勿把真实密钥写入仓库）

| 变量 | 说明 |
|------|------|
| `PRIVACY_POLICY_URL` | 隐私政策页面 URL（默认 example.com） |
| `API_BASE_URL` | 后端基址（默认 `https://pangbao.cuplay.top`） |
| `WX_LOGIN_CODE` | 无移动 SDK / 无网页授权配置时的联调临时 code，作为登录请求体字段 **`jsCode`** 提交 |
| `WECHAT_APP_ID` | 微信开放平台**移动应用** AppId（`fluwx.registerApi`）；与 `pubspec.yaml` 中 `fluwx.app_id` 保持一致 |
| `WECHAT_UNIVERSAL_LINK` | iOS Universal Links 前缀（须与开放平台、`pubspec.yaml` → `fluwx.ios.universal_link` 一致） |
| `WECHAT_WEB_APP_ID` | **网站应用** AppId；留空则网页授权使用 `WECHAT_APP_ID` |
| `WECHAT_OAUTH_REDIRECT_URI` | 网页授权回调完整 URL，须登记为 `…/auth/wechat/callback`（与路由一致） |
| `WS_HISTORY_URL` | 历史 WebSocket **完整 URL**；**留空**时根据 `API_BASE_URL` 自动推导 `ws(s)://…/device/app/ws/history` |
| `REFRESH_TOKEN_PATH` | 静默刷新 access token 的 POST path（相对 [apiBaseUrl]）；请求体字段 **`refreshToken`**；设为空字符串可关闭 |
| `IOS_APP_STORE_ID` | App Store 数字 ID（占位） |
| `MOCK_NEWER_VERSION` | `true` 时强制出现「发现新版本」提示（联调 UI） |
| `FORCE_IPV4` | `true` 时 Android/iOS 原生端 HTTP/WebSocket 仅走 IPv4（部分双栈网络连通性止血）；默认 `false` |

示例：

```bash
flutter run --dart-define=MOCK_NEWER_VERSION=true --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy
flutter run -d android --dart-define=FORCE_IPV4=true
```

### 登录（微信 + 账号密码）

- **当前方式**：登录页提供 **账号密码登录** 与 **微信登录** 双入口。
- **注册入口**：登录页点击“注册账号”会进入独立注册页（风格与登录页一致），不再在登录页内直接提交注册。
- **注册校验**：注册页新增“确认密码”，客户端提交前必须校验与“密码”一致，不一致时阻止请求并提示。
- **账号密码主登录**：`POST /device/app/api/username_login`，请求体 `account`、`password`；成功返回并持久化 `accessToken` / `refreshToken`，再进入主页流程。
- **账号规则**：客户端提交前会对 `account` 执行 `trim + lowercase`；规则为 `4-32` 位且仅允许 `a-z0-9_`；`password` 长度 `6-64`。
- **微信登录**：客户端通过微信授权获取临时 code，再请求 **`POST /device/app/api/login`** 建立会话。
- **Web**：若已配置 `WECHAT_WEB_APP_ID` / `WECHAT_OAUTH_REDIRECT_URI`，点击微信登录会跳转微信网页授权；回调返回 `/auth/wechat/callback` 后继续登录流程。
- **开发联调**：`WX_LOGIN_CODE` 仍可作为微信链路开发兜底；账号密码链路不依赖该参数。

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

- 事件 **`logo`**：`GET /device/history/api/event/options` 返回 **CDN 绝对 URL**（如 `https://resorce.cuplay.top/event/...`），客户端直接使用。
- **`downloadUrl`**（版本检查）等仍可能为 path-only，经 `resolveGatewayAbsoluteUrl` 与 `API_BASE_URL` 拼接。

### 微信登录（fluwx + 网页 OAuth）

1. **勿提交 AppSecret**；客户端仅需 AppId、回调域名等公开配置。  
2. **Android**：`fluwx` 已通过插件 `AndroidManifest` 合并 `WXEntryActivity` 与 `queries`（微信包名 `com.tencent.mm`）；请保证应用包名与签名与开放平台「移动应用」登记一致。  
3. **iOS**：将 `pubspec.yaml` 中 `fluwx.app_id`、`fluwx.ios.universal_link` 替换为真实值，与 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK`、`IOS_ASSOCIATED_DOMAIN` 及 `apple-app-site-association` 一致。`WECHAT_UNIVERSAL_LINK` 必须是完整 `https://` 前缀路径，**不得包含 `*`**。  
4. **Web**：使用 `PathUrlStrategy`（见 `main.dart`）；在开放平台登记网站应用，**授权回调域**与 `WECHAT_OAUTH_REDIRECT_URI` 完全一致（路径为 `/auth/wechat/callback`）。本地示例：`http://localhost:xxxx/auth/wechat/callback`（端口与 `flutter run` 一致）。  
5. **iOS CI 发布门禁**：`Build iOS IPA` 在非 `legacy` 模式会 fail-fast 校验 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK`、`IOS_ASSOCIATED_DOMAIN`，并校验 `IOS_ASSOCIATED_DOMAIN` 与 `WECHAT_UNIVERSAL_LINK` 域名一致。缺失或不一致会直接阻断产包。  
6. **运行示例**（登录页会直接调用微信登录；`WX_LOGIN_CODE` 仅用于开发联调兜底）：

```bash
cd app
flutter run -d android --dart-define=WECHAT_APP_ID=wx你的移动应用AppId
flutter run -d chrome --dart-define=WECHAT_APP_ID=wx你的AppId --dart-define=WECHAT_OAUTH_REDIRECT_URI=http://localhost:8080/auth/wechat/callback
```

#### iOS 微信登录最小排障顺序（出现“点击无反应”时）

1. 先确认构建日志中存在 `--dart-define=WECHAT_APP_ID=...` 与 `--dart-define=WECHAT_UNIVERSAL_LINK=...`。
2. 确认 `WECHAT_UNIVERSAL_LINK` 为完整 `https://域名/路径前缀/`，不含 `*`。
3. 确认 `IOS_ASSOCIATED_DOMAIN=applinks:<同域名>`，且与 `WECHAT_UNIVERSAL_LINK` 的域名一致。
4. 确认域名可访问 `apple-app-site-association`，内容包含当前 App 的 TeamID.BundleID。
5. 若仍失败，在 iOS 真机复现以下三类场景：成功授权、取消授权、未安装微信/配置错误，确保均有明确提示。

### 接口联调（网关）

```bash
cd app
flutter run -d chrome --dart-define=WX_LOGIN_CODE=你的微信code
flutter run -d chrome --dart-define=WX_LOGIN_CODE=xxx --dart-define=WS_HISTORY_URL=wss://pangbao.cuplay.top/device/app/ws/history
```

- 未登录也可进主页；历史为空会出现 **「请绑定宝宝信息」** 条，点击未登录去登录、已登录去 **`/settings/bind-baby`**。
- 业务 `code != 0` 时通过 `apiToastProvider` 提示 `message`。
- **微信**：网关仍以 **`jsCode`** 接收临时 code；当前产品登录页直接走微信登录，联调可额外使用 `WX_LOGIN_CODE` 兜底。
- **账号体系（新增）**：
  - 匿名：`POST /device/app/api/username_login`、`POST /device/app/api/user/username/register`、`POST /device/app/api/user/username/login`（仅业务校验，不写 token）。
  - Bearer：`POST /device/app/api/user/username/bindwx`、`POST /device/app/api/user/username/bind_device`、`POST /device/app/api/user/username/change_password`、`POST /device/app/api/user/wx/create_username`。
  - 推荐回归：账号主登录 → token 刷新 → 查询画像；设置页账号管理中改密/绑定微信/绑定设备/微信补齐账号。
- **主页聊天与历史 WebSocket**：
  - 进入首页仍会 **`GET /device/history/api/list`** 拉一次初始列表。
  - 须配置 **`WS_HISTORY_URL`**（或通过 `API_BASE_URL` 自动推导 ws 地址）。历史 WebSocket 建连并收到服务端 **`auth_ok`** 之前，客户端 **不会** 调用 `POST /device/history/api/chat`；未就绪时会有 Toast，可在首页 AppBar 使用 **云形图标「重连历史」** 手动重连。
  - `chat` 成功后 **不再** 自动请求 list；列表增量依赖服务端经 WebSocket 推送的 `create`/`update`/`delete` 等事件（需网关保证 `chat` 完成后有对应推送）。

### 真机 / 浏览器冒烟（需本地执行）

- **登录**：在 Android / iOS / Web 完成一次账号密码登录并进入主页；在可用环境完成一次微信登录并进入主页；失败时应展示服务端业务 message 或网络错误。
- **账号联调**：验证注册、改密、绑定微信、绑定设备、微信补齐用户名密码、业务登录校验（不写 token）等流程。
- **Android 更新**：在能访问版本接口与 APK 下载 URL 的环境下，从更新弹窗执行「下载并安装」；若系统拦截，按提示到 **设置 → 允许安装未知应用 / 来自此来源的应用**（华为、小米、OPPO、vivo 等路径略有差异）授权后重试。
- **历史微信流程**（若重新开放 UI）：在 Android、iOS 真机与 HTTPS 测试域 Web 各完成一次：打开微信 → 授权 → 回到应用 → 进入主页；取消授权时应有 Toast 且应用不崩溃。详细任务见 `openspec/changes/app-wechat-sdk-login/tasks.md`。

## 交互说明（M2）

- **主页历史列表**：每条为富文本摘要；点击一行在主页底部弹出 **编辑 Sheet**，可滚轮调整时分（不改日期）、编辑备注/用量、停止计时或删除，保存走 `POST /device/history/api/event/update`。更新请求体中 **`startTime` / `endTime` 为 Unix 秒级整型时间戳**（与列表解析一致，非毫秒）。`pending:*` 乐观记录在同步完成前为只读。
- **Web 主输入**：默认与 App 一致为**事件按钮网格**；贴边 dock 可在**按钮 ↔ 文字**间切换。文字模式下 **Enter** 或「提交」走 `POST /device/history/api/chat`。游客或未绑宝宝时仅展示按钮、不显示 dock。
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
