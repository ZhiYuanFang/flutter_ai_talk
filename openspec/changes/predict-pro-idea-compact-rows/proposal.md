## Why

Pro 墙想法列表头部「被采纳…免费开通 1 个月」占纵向空间且本版不履约；每条「家长昵称 + 缩进矩形」也偏重。需要收成紧凑列表行，并保留本人整行 accent 高亮与火赞。

## What Changes

- **去掉**有数据态小字：「被采纳的意见提供者后续可联系管理者，获取免费开通Pro版1个月的资格」。
- **去掉**每条「{宝宝名}的家长」展示（API 字段可仍解析，UI 不渲染）。
- 每条改为**列表 bullet 行**：左侧列表符号 + 想法正文，右侧火标热度；正文与热度**纵向居中**对齐。
- `isMine`：**整行**用档位 accent 高亮（非仅矩形描边）。
- **保留**：标题「可能扩展包含以下能力」、小字「热度越高越可能被收纳进Pro功能中」、火赞切换、「我有更多想法」+ 付费意愿小字、空态圆钮。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-pro-idea-client`：非空态文案与行布局；本人整行 accent；去掉采纳资格文案与家长昵称。

## Impact

- Flutter：`predict_pro_idea_panel.dart`（及 `_IdeaCard`）。
- 无 API / Go 契约变更；无 Android 原生；Release N/A。
- 叠在 `predict-pro-idea-wall` 之上。
