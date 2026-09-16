## 1. 依赖与 Android 接入

- [x] 1.1 在 `app/pubspec.yaml` 增加 `china_push`，按包 README 配置 Android Gradle / manifestPlaceholders / 本地密钥文件（gitignore）
- [x] 1.2 核对 AGConnect / 现有华为相关配置与 `china_push` 文档无冲突；必要时最小调整 `build.gradle.kts`

## 2. 推送取 token 改 china_push

- [x] 2.1 实现 Android：`china_push` 初始化 → regId + manufacturer → 映射 `hms|mipush`
- [x] 2.2 未映射厂商或 init/token 失败：跳过注册、打 `AppDebugLog`，不崩溃
- [x] 2.3 iOS 保持原生 APNs 路径与 `channel=apns`
- [x] 2.4 拆除自研 Android HMS/MiPush 源码、mipush/nomipush 条件路径及无用 MethodChannel Android 分支；更新 `app/README.md` 推送说明

## 3. 预测临近 pending 同步

- [x] 3.1 新增 `PUT /device/api/predict/imminent/pending` 客户端调用（对齐 Go CLIENT.md）
- [x] 3.2 在本地预测刷新完成后触发全量同步；无可上报时传空 `events`；single-flight / 短熔断
- [x] 3.3 确认同步不依赖推送 register 成功

## 4. Release / R8（china_push 阶段）

- [x] 4.1 更新 `app/android/app/proguard-rules.pro`
- [x] 4.2 `flutter build apk --release` 通过（china_push 接入后）

## 5. 全局推送注册（对齐 Go extract-push-service）

- [x] 5.1 注册/注销改走 `ApiClient`：`POST /app/api/push/register` 与 `POST /app/api/push/unregister`；移除对 `UcgApiClient` `/ucg/app/api/push/*` 的调用
- [x] 5.2 门闸改为仅 `session.isLoggedIn`；移除 `isUcgWxAccountBound` /「绑微信」前置；文档注明服务端 wxId=登录用户
- [x] 5.3 从 `activateUcgHomeSession` 拆除 push 步骤；在登录成功 / 冷启已登录后触发全局 `ensureRegistered`（不依赖 UCG chat WS）
- [x] 5.4 登出仍 `unregister`；保留 deviceKey / single-flight / 熔断 / 指纹去重
- [x] 5.5 更新 `app/README.md`：全局路径、登录门闸、与 UCG 解耦说明
- [x] 5.6 修复 china_push `\${HMS_APP_ID}` 合并残留反斜杠：宿主 Manifest `tools:node=replace`；合并后 Gradle 剥离 `android:value="\`
- [x] 5.7 移除无效的 `copyAgconnectAssets`（注入 AppId 路径不读 assets JSON）；README 标明不接 AGConnect 插件
- [x] 5.8 纯数字 AppId 经 `resValue` + `@string` 注入，避免 Bundle Integer / `getString` ClassCast
- [x] 5.9 补充 HMS Core 所需 `com.huawei.hms.client.appid`/`cpid` meta-data（修复日志 `app_id:|` / 907135000）
- [x] 5.10 App 创建 Android 通知渠道 `push_default`，与 Go `push_hms.go` 的 `channelId` 对齐

## 6. 联调验收（手工）

- [ ] 6.1 真机：仅登录（无需绑微信）后 register 成功（网关可见 `POST /app/api/push/register`）
- [ ] 6.2 预测刷新后 pending 上报；有条件时验证约 `nextAt-5min` 离线可见推送
- [ ] 6.3 未配置密钥或其它厂商机型：失败可接受、App 不崩
- [ ] 6.4 确认无任何 `/ucg/app/api/push/*` 请求
- [ ] 6.5 华为机：合并 Manifest 中 `HMS_APP_ID` 无反斜杠；无 `907135000`；`[UcgPush] china_push init ok`
