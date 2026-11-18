## Why

申请华为绿色应用 / 应用市场上架时，审核要求：收集个人信息前须以明确方式征求隐私政策同意，且不得仅用「登录即代表同意」；敏感权限（如相机）申请时须同步告知用途。当前冷启动无首启隐私门闩，登录页为隐含同意文案，宝宝共享扫码直接弹系统相机权限，存在合规缺口。

## What Changes

- 新增**首启隐私门闩**：未本地同意时，全屏展示 WebView 加载 `AppEnv.privacyPolicyUrl`（无额外标题栏，页面自带标题；内容可滚动）；底栏「不同意并退出」「同意并继续」。不同意则退出进程；同意后持久化，再继续冷启动联网（事件目录、iOS 探针、推送 init、设备型号上报等）。
- 系统返回键在门闩页等同「不同意并退出」。
- **登录 / 注册页**：去掉「登录即代表您已阅读并同意」隐含文案；改为默认未勾选的「已阅读并同意《用户协议》和《隐私政策》」；保留两份可点链接（`userAgreementUrl` / `privacyPolicyUrl`，二者为不同文档）。未勾选时点登录/微信登录：弹确认「是否同意…」→ 确定则自动勾选并继续；取消则停留。
- **宝宝共享扫码**：在系统 `Permission.camera.request` 前增加用途说明玻璃框（对齐横屏麦克风节奏）；取消/拒绝不得循环硬弹。
- **不在本次范围**：横屏语音 AI 申明材料、隐私政策 HTML 正文修订、UGC/定位权限、移除 `geolocator` 依赖。

## Capabilities

### New Capabilities

- `first-launch-privacy-consent`：冷启动隐私政策 WebView 门闩、同意持久化、不同意退出、同意前阻断采集侧联网。
- `auth-agreement-checkbox`：登录/注册协议勾选与未勾选时的确认再登录流程。
- `camera-scan-permission-rationale`：宝宝共享扫码相机权限用途先告知。

### Modified Capabilities

（无。不修改既有 AI 对话知情同意、UCG 定位 consent 等 Requirement 正文；本变更新增平行门闩。）

## Impact

- **代码**：冷启动路径（`main` / `PangbaoApp` / `ColdStartBootstrap`）、登录与注册 UI（`auth_ui` / `login_screen` / `register_screen`）、`BabyQrScanScreen`；新增本地同意 Store；可能新增 Debug tag（若需）。
- **网络**：同意前不得触发会向服务端暴露 IP/设备信息的业务请求（含游客事件目录拉取、iOS `version/check` 探针、推送 token 注册、设备型号上报）。
- **基线**：对照 `openspec/specs/v2.2.2.md`。
- **材料**：绿色应用仍须另行准备敏感权限场景截图（相机/麦克风等）；本变更不产出截图包。
