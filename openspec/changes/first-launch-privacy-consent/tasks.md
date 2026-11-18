## 1. 首启同意存储与门闩 UI

- [x] 1.1 新增本地同意 Store（SharedPreferences 键如 `privacy_policy_consent_v1`：读/写已同意）
- [x] 1.2 实现首启隐私门闩页：可滚动 WebView 加载 `AppEnv.privacyPolicyUrl`；无 AppBar/额外标题；固定底栏「不同意并退出」「同意并继续」；加载中进度与失败重试
- [x] 1.3 不同意 / 系统返回：退出进程且不写同意；同意：写 Store 后关闭门闩

## 2. 冷启动接入（同意前阻断联网）

- [x] 2.1 在 `PangbaoApp` 冷启动路径中：未同意则只展示门闩（可先 hide native splash），**不得**调用 `IosNetworkPermissionProbe`、`ColdStartBackgroundSync`、以及会触发推送注册 / `syncDeviceModelReport` 的后续链路
- [x] 2.2 同意后（本会话刚同意或 prefs 已同意）再走既有 `_runColdStart` 与后续 sync
- [x] 2.3 若需 Debug 日志：三联改 `AppDebugLog` / `logcat_api_http.ps1` / `app/README.md`（否则可跳过）

## 3. 登录 / 注册协议勾选

- [x] 3.1 改造 `buildAuthPrivacyAgreement`（或并列组件）：默认未勾选；文案为已阅读并同意《用户协议》和《隐私政策》；去掉「登录/注册即代表…」隐含同意
- [x] 3.2 `login_screen` / `register_screen`：主登录、微信登录、注册提交前校验勾选；未勾选则玻璃确认 → 确定自动勾选并继续，取消则中止
- [x] 3.3 确认两链接分别打开 `userAgreementUrl` 与 `privacyPolicyUrl`

## 4. 扫码相机用途说明

- [x] 4.1 在 `BabyQrScanScreen`：未授权时先玻璃用途框（扫描宝宝共享码 / 家庭共享），确认后再 `Permission.camera.request`；已授权跳过；取消不 request、不进 ready 扫码态

## 5. 手工验收

- [ ] 5.1 清同意 prefs 后冷启动：见门闩；不同意退出；再开仍见门闩
- [ ] 5.2 同意后进业务；抓包/日志确认同意前无目录与 iOS 探针请求
- [ ] 5.3 登录未勾选 → 确认 → 自动勾选并登录；用户协议与隐私政策打开内容不同
- [ ] 5.4 扫码：未授权先用途框再系统权限框

## 6. 登录 UI 定稿（不与首启同步）

- [x] 6.1 协议勾选改为圆形；《用户协议》《隐私政策》下划线且尽量单行；不与首启同意同步
- [x] 6.2 Apple / 微信改为横向图标+底注；微信使用 `assets/images/wx.png`
- [x] 6.3 Android 宿主 `<queries>` 显式声明 `com.tencent.mm`；登录页检测安装前先 `registerApi`
