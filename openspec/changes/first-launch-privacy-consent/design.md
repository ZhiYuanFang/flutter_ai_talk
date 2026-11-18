## Context

华为等应用商店要求：处理个人信息前明示隐私政策并取得自愿明确同意；登录不得仅用「登录即代表同意」；敏感权限须在系统弹窗前说明用途。

当前冷启动（`main` → `PangbaoApp._runColdStart`）在无首启同意的情况下即可进入 `/home`，游客仍会拉事件目录（服务端可见 IP）；iOS 另有 `version/check` 探针。登录页 `buildAuthPrivacyAgreement` 使用「登录即代表…」文案。`BabyQrScanScreen` 在 `initState` 直接 `Permission.camera.request()`。横屏麦克风已有「用途框 → 再 request」范例（`landscape_mic_permission.dart`）。

约束：对照 `openspec/project.md` 与基线 `openspec/specs/v2.2.2.md`；弹框内若有输入控件须由弹层 State 持有 controller（本门闩以 WebView 为主）；Debug 日志走 `AppDebugLog` 白名单。

## Goals / Non-Goals

**Goals:**

- 未同意隐私政策前阻断「会向服务端暴露个人信息/网络标识」的冷启动路径。
- 首启 UI：无标题栏 WebView + 底栏同意/退出；不同意退出进程。
- 登录/注册改为勾选协议；未勾选点登录时确认并自动勾选。
- 扫码相机用途先告知。

**Non-Goals:**

- 修订线上 `privacy-policy.html` / `user-agreement.html` 正文内容。
- 关闭横屏语音或补充生成式 AI 申明材料。
- 移除 `geolocator` 依赖或改 UGC 定位逻辑。
- 提供「仅浏览」无联网模式。
- 新增自动化测试文件。

## Decisions

1. **门闩时机：同意前不跑 `_runColdStart` 内会联网的业务**  
   - 在展示启动遮罩之后、调用会触发目录/探针/后续 sync 的路径之前读取本地同意态。  
   - 未同意：只展示隐私门闩（可先 `hideNativeSplash` 以免双层闪屏），**不得**调用 `IosNetworkPermissionProbe.run`、`ColdStartBackgroundSync`、已登录侧的推送注册与 `syncDeviceModelReport`。  
   - 同意后：写入 prefs，再走现有 `_runColdStart` / 后续 sync。  
   - 备选：先跑 bootstrap 再挡 UI → 否决（已产生 IP 采集）。

2. **UI：全屏门闩，非小 Alert**  
   - 上：`WebView` 加载 `AppEnv.privacyPolicyUrl`，可滚动；**无** AppBar/弹窗标题（网页自带「胖宝隐私政策」）。  
   - 下：固定底栏「不同意并退出」「同意并继续」。  
   - 加载中可显示细进度；加载失败须可重试，**不得**因失败默认同意。  
   - 系统返回 / Android back：等同不同意并退出。  
   - 复用 `webview_flutter`（与 `PolicyScreen` 同源）；门闩页可独立组件以免与设置内带 AppBar 的 `PolicyScreen` 混用标题。

3. **不同意 = 退出**  
   - `SystemNavigator.pop()`（或平台等价）；不提供访客浏览。  
   - 不清除已写入的「未同意」以外状态；下次冷启动仍出门闩。

4. **同意持久化**  
   - SharedPreferences 布尔键（如 `privacy_policy_consent_v1`）；仅「同意并继续」写 true。  
   - 本次不强制政策版本号再同意；若日后政策大改可换 key（Open Question 可留）。

5. **登录/注册勾选**  
   - 保留《用户协议》与《隐私政策》两个链接（默认 URL 不同：`user-agreement.html` / `privacy-policy.html`）。  
   - 默认未勾选；**不与首启隐私同意同步**（登录层另含用户协议）。  
   - 未勾选点主登录或微信/Apple 登录 → 玻璃确认 → 确定则勾选并继续原登录逻辑。  
   - 勾选外形为**圆形**；协议链接带**下划线**，尽量**单行**展示。  
   - 注册页同步同一勾选样式。  
   - Apple / 微信登录改为横向**图标+底注**（微信图标 `assets/images/wx.png`；底注「apple」「微信」）。  
   - Android 11+：宿主 Manifest `<queries>` **显式**声明 `com.tencent.mm`（与 fluwx 合并对齐）。  
   - 登录页展示微信入口前须先 `fluwx.registerApi`，再 `isWeChatInstalled`（未 register 时 Android 抛 `Unassigned WxApi`，会被误当成未安装）。

6. **扫码相机**  
   - 对齐 `ensureLandscapeMicPermission`：未授权时先玻璃用途框，确认后再 `Permission.camera.request()`；已授权跳过用途框。  
   - 文案要点：扫描宝宝共享码以加入家庭共享；非其它用途。

7. **与设备型号上报的关系**  
   - `syncDeviceModelReport` 仅已登录触发；仍须保证首启未同意时即使用户本地残留登录态，也不得在同意前上报（门闩挡住整个 cold start 联网即可）。

## Risks / Trade-offs

- [未同意前原生 SDK 静默初始化] → 缓解：Flutter 侧推迟 `ChinaPush.init` / 探针 / 目录；若厂商 Application 级自启无法完全消除，在隐私政策 SDK 列表中如实披露（正文修订另案）。  
- [WebView 加载失败用户无法阅读] → 缓解：失败提示 + 重试；底栏仍可退出；不自动同意。  
- [双同意摩擦：首启 + 登录勾选] → 接受：满足商店对「进 App」与「注册登录」两层明示的常见要求。  
- [退出后用户以为闪退] → 文案用「不同意并退出」降低误解。

## Migration Plan

- 新装用户：首次必见门闩。  
- 已装用户升级：prefs 无同意键 → 下次冷启动见门闩（可能已登录也会先出门闩再进业务）。  
- 回滚：去掉门闩读取即恢复旧行为；prefs 键可残留无害。

## Open Questions

- 政策大改是否引入版本号强制再同意（本版不做）。  
- 历史记录「拍照」路径是否同期加用途框（本版以扫码为准；若绿色截图需要可加任务）。
