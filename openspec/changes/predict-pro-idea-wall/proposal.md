## Why

预测两档墙 Pro 档本版不做开通 CTA，产品要把 Pro 做成「收集用户想法」：正文仍用服务端 catalog 渲染；墙内展示想法空态/列表（含热度点赞与本人高亮）；另开玻璃 Sheet 提交想法。依赖 Go `predict-pro-idea-hub`。

## What Changes

- Pro 正文继续仅渲染 catalog `title` / `description`（MD）/ `logo`（空 description 走既有短兜底）。
- **卡外底栏不变**：未开通「敬请期待」、已开通「正在使用」（浅灰底黑字状态标签）；**不得**把底栏改成提交入口。
- 墙内想法区（空态与有数据均展示，非「有数据才出现」）：
  - **空态**：底对齐圆形「我有想法」+ 心跳动画；圆钮下小字「具备什么功能，你愿意付费开通」。
  - **有数据**：标题「可能扩展包含以下能力」；小字「热度越高越可能被收纳进Pro功能中」；换行小字「被采纳的意见提供者后续可联系管理者，获取免费开通Pro版1个月的资格」（本版仅文案）；想法卡片（`{宝宝名}的家长`、矩形正文缩进、右侧火标热度可赞/取消）；`isMine` 颜色高亮；底钮「我有更多想法」+ 同款付费意愿小字。
- **新建**玻璃拟态 Sheet（**不改**两档墙 dialog 结构）输入想法并发送；Sheet 默认贴底；键盘弹出时 **整张 Sheet** 被顶起；成功后刷新墙内想法。
- 列表排序跟服务端（新在前）；废弃 `· ` 简列表与「底栏改提交意见」。
- **不改**：基础版；设置反馈；Pro 支付/试用 CTA；本版无采纳履约。

## Capabilities

### New Capabilities

- `predict-pro-idea-client`：list/submit/like 客户端、墙内空态/列表、本人高亮、作曲 Sheet。

### Modified Capabilities

- `predict-capability-tier-wall`：Pro 档叠加想法区与入口；**明确保留**卡外「敬请期待/正在使用」脚。

## Impact

- Flutter：`predict_capability_tier_wall.dart`、新 repository/provider/Sheet UI；debug tag 若新增须三联改。
- 依赖 Go：`/device/app/api/predict-pro-ideas/*`。
- 无 Android 原生；Release N/A。
