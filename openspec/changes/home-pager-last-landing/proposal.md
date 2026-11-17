## Why

主壳冷启写死着陆智能预测页。只关心喂养记账的用户每次都要先经过预测再滑到喂养。需要记住上次停留的喂养/预测页，下次冷启直接回到该习惯页。

## What Changes

- 用户在主壳 **喂养** 与 **预测** 之间切换时，客户端 MUST 将当前页写入本地 `lastPage`（或等价键）。
- 下次冷启进入 `/home` 时，主壳 PageView `initialPage` MUST 为上次合法记忆页；无记忆或非法时 MUST 回落预测。
- **UCG 页 MUST NOT 写入 lastPage**；若当前可见为 UCG，MUST NOT 用 UCG 覆盖已存的喂养/预测记忆；冷启 MUST NOT 因记忆而直接着陆 UCG。
- 显式切页请求（深链、`requestPage`、「去记录」等）MUST 仍优先于记忆着陆。
- 冷启实际着陆页的 page-show usage MUST 按真实着陆页上报（落喂养报 feeding，落预测报 prediction）。

## Capabilities

### New Capabilities

- `home-pager-last-landing`：主壳喂养/预测 lastPage 持久化与冷启着陆。

### Modified Capabilities

- `client-usage-report`：冷启 page-show 对齐「记忆着陆」（不再仅假定永远落预测）。

## Impact

- **Flutter**：`UcgHomeShell`（`PageController.initialPage`、`_onPageChanged` 写盘）、新建 prefs store、可选 wipe 策略。
- **无 Go API 变更**。
- **风险**：异步读盘导致先闪预测再跳喂养——设计要求同步可读或壳挂载前 hydrate。
