## Why

成长轨迹已上线，但家长看不到当日还能预测几次，容易误触日限；结果文案按天拆分也不符合「7 天内注意点」的阅读预期。同时将女性宝宝默认经典主题色从粉红改为更清新的绿色，统一产品视觉。

## What Changes

- **成长轨迹日限感知**：已开通且 CTA 可见时，在「轨迹预测 / 重新预测」按钮下方展示小字「今日已用 {used}/{limit} 次」；次数用尽仍可点，由服务端拒后 Toast（不本地灰掉）。
- **契约**：`GET latest` 与成功 `result` SSE 回传账号维 `usedToday` / `dailyLimit`（与现有 wxID 日限一致；权益已是账号维，本变更不改开通主体）。
- **结果文案（Python）**：生成 Markdown **不得**按「第 N 天」拆日程；改为未来 7 天可能发生什么 + 需要注意什么等整段结构，并多用 emoji 提升可读性；兜底模板同步。
- **女性宝宝默认经典色**：**BREAKING**（相对基线色值）——`sexPrimary(BabySex.female)` 由 `#E91E63` 改为 **`#2CB771`（`0xFF2CB771`）**；仅影响未覆盖自定义主题时的性别默认种子，不强制改写用户已持久化的自定义色。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `growth-trajectory-predict`：日限用量展示与 API 字段；结果 Markdown 结构（去按日拆分、多 emoji）。
- `app-theme-customization`：女性宝宝经典 `sexPrimary` 由玫瑰红改为 `#2CB771`。
- `settings-center`：主题默认值表述由「女 → 红色系」改为「女 → 绿色系 `#2CB771`」。

## Impact

- **Flutter**：`ai_analysis_screen` CTA 下方小字；`growth_trajectory_*` 消费用量字段；`theme_preset.dart` `sexPrimary` 女宝色。
- **Go**：`latest` / `result` 增加 `usedToday`、`dailyLimit`。
- **Python**：`generate` 提示词与 fallback。
- 对照基线 `openspec/specs/v2.1.0.md`（`app-theme-customization`）；成长轨迹见 change `growth-trajectory-predict`。
- 不自动新建 `**/test/**`。
