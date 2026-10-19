## Why

胖宝需要在用户已经用过喂养记录之后，收集他们认为 App 做得满意的地方。弹窗必须跟随后端活动开关与有效期，并且只在用户提交后才不再出现；客户端不能各自写死文案。

## What Changes

- 已登录主壳 `UcgHomeShell` 在既有启动弹窗（notify，然后 version）结束之后，判断当前设备是否已有历史喂养数据缓存；有缓存才请求兄弟仓 device-service `GET /device/app/api/survey/current`。
- 服务端返回需要展示时，用 sheet 展示说明与可多选选项，底部提供「更多意见」输入；允许一个都不选、只写意见后提交到 `POST /device/app/api/survey/submit`。意见 trim 后超过 1000 个 Unicode 码位时不发 POST。
- 关闭 sheet、双空或 POST 失败都不算交卷。提交校验和 POST 失败都在提交按钮上方展示文案，不 toast，sheet 保持打开。下次冷启动仍可再问。同一主壳挂载周期内不重复弹。resume 与挂载期间的中途登录不补弹。
- 未登录、无喂养缓存、接口失败或 `show=false` 时不弹。不改 notify / version 的先后顺序。
- 颜色走 `AppColor`；意见输入框的 `TextEditingController` 由 sheet State 持有。该 GET 属于主壳副作用 HTTP，须 single-flight，失败静默且不得无限重试。

## Capabilities

### New Capabilities

- `home-satisfaction-survey`：主壳在喂养缓存门闩下拉取满意度问卷、sheet 多选与意见提交，以及「仅提交成功才结束本轮」。

### Modified Capabilities

- （无）。`app-notify-banner` 仍为 notify 先于 version；本能力只接在该编排之后，不改其需求正文。

## Impact

- **主壳**：`app/lib/ucg/ui/ucg_home_shell.dart`、`app/lib/ui/home_shell_dialog_bootstrap.dart`（或紧随其后的同级编排）。
- **喂养缓存门闩**：读取当前 `deviceNo` 的 `HomeHistoryStore` / `homeHistory` 内存列表是否非空；Web 无磁盘缓存时以内存列表为准。不改历史缓存格式。
- **网络**：新增 device App API 客户端方法；Bearer 登录态；不新增 WebSocket。
- **基线**：对照 `openspec/specs/v2.1.3.md` 的主壳启动弹窗与副作用 HTTP 约定；不改历史 WS 建连时机。
- **后端**：契约由 `go_ai_talk` 变更 `device-satisfaction-survey` 提供；本仓不实现服务端。
