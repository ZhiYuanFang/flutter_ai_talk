## Why

智能预测页「值得留意」在冷启动后常永久显示「加载中…」，logcat 无 `[CareAlert]`、无 `GET .../care-alert/daily`。根因是 ensure 门闸（登录 + deviceNo + range 非空）失败时静默 return，且首帧 postFrame 时 range 往往未就绪；range 已就绪后若 listen 未补拉（或 deviceNo clear 后无再 ensure），状态停在 `ready=false`——UI 把「未就绪」也渲染成「加载中…」，形成假加载。

## What Changes

- 当 `predictionCareAlertFetchAllowed` 从不可用变为可用时，**必须**触发 care-alert `ensureLoaded`（不依赖仅「range wasEmpty」的窄 listen）。
- 门闸跳过 / ensure 跳过 **必须**打 `[CareAlert]` 诊断日志（含门闸因子摘要），禁止静默 return。
- `deviceNo` 变更导致 clear 后，在仍允许拉取且预测页可见时 **必须**再 ensure。
- UI：区分真加载（`loading==true`）与未拉取/未就绪（`!ready && !loading`）——后者不得再伪装「加载中…」，应走可刷新空态族（与 `care-alert-widget-tip-align` VIP 空态一致，或至少提供刷新）。
- 不放宽「冷态无真历史禁止副作用 HTTP」门闸本身。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `llm-care-alert-daily`：补强可见时 ensure 触发条件、门闸可观测性、假加载 UI 禁止。
- `smart-prediction-page`：值得留意卡片未就绪态不得永久「加载中…」。

## Impact

- 代码：`ucg_home_shell.dart`（ensure 触发）、`prediction_care_alert_provider.dart`（门闸日志 / clear 后补拉钩子）、`smart_prediction_screen.dart`（`_CareAlertPanel` 假加载）。
- 与未归档 `care-alert-widget-tip-align` 空态族对齐；无新 API、无 Android 原生变更、不新建 `**/test/**`。
