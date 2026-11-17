## Why

预测免费/Pro 两档墙的文案与交互仍偏「可切换开通」：右上关闭、假按钮脚、「当前可用」、免费版旁 upgrade 暗示、Pro 仍露出试用/支付。需要改成说明向墙：点外部关闭、能力用 Markdown 可读展示、本版不开放 Pro 开通，并让 Hub 侧 `description` 能存长 MD（Go `VARCHAR(512)` 不够）。

## What Changes

- 两档墙：去掉右上 ✕；点遮罩/外部关闭（修全屏吞点击）。
- Free：客户端硬编码 Markdown 能力清单（行首 emoji 标签）；禁算法/亲和等词；不含「记一条」卖点。
- Pro：`title` / `description` / `logo` 仍来自 catalog；`description` 按 Markdown 渲染；logo 与 Free 同框 `BoxFit.contain`（禁止 cover 横向撑满）。
- 底栏：本版无任何可点开通；非可点态**不得**呈按钮（透底 + 事件色字）。Free 脚恒「正在使用」（含已是 Pro）；Pro 未开通「敬请期待」，已开通「正在使用」。
- 3h 卡：隐藏 `Icons.upgrade`（整卡仍可开墙）。
- **Go**（兄弟仓 `go_ai_talk`）：`feature_def.description` 由 `VARCHAR(512)` 改为 `TEXT`（新建表 + EnsureSchema 幂等 ALTER）。

## Capabilities

### New Capabilities

- `feature-catalog-description`：Go `feature_def.description` 为 TEXT，Hub/App 透传长 Markdown。

### Modified Capabilities

- `predict-capability-tier-wall`：墙关闭方式、MD 正文、logo fit、底栏文案与非按钮态、本版禁用 Pro 开通 CTA。
- `predict-free-pro-chrome`：3h 免费后缀旁不再展示 upgrade 图标。

## Impact

- Flutter：`predict_capability_tier_wall.dart`、`predict_capability_tier.dart`、`smart_prediction_screen.dart`（3h）；复用既有 `markdown_widget`。
- Go：`internal/services/cash/schema.go`（及必要时 Admin 无长度 512 假设）；无 App API 字段名变更。
- 无 Android 原生；Release APK N/A（纯 Dart + 服务端 schema）。
