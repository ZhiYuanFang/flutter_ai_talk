## Why

AI 分析 Hub 两张能力卡目前用中性介绍文案 + 白底样张区，难以让未开通用户产生开通欲望，也难以刺激已开通用户去使用。需改为「模拟结果样张」+ 功能色氛围，并让剩余时效贴近标题，强化转化与复用冲动。

## What Changes

- 喂养 / 成长卡的 blurb 改为 ≤50 字模拟内容（多表情、关键字加粗），浅功能色圆角底，替代原白底说明文；样张字色加深。
- 模拟角标贴在样张浅色底外侧左上（仍在玻璃卡内），标明「模拟内容」及「你可以得到这样的效果」；非整张功能卡外侧。
- 功能剩余天数（及等价时效文案）改到标题行右侧小字展示；不再作为卡内独立 meta 主展示。
- 卡内文案（标题、模拟样张、时效小字、底部 body / 开通心跳等）跟功能色；喂养资格进度数字/文案也跟 accent。
- 未开通与已开通、喂养未合格态均保留模拟样张（转化目标一致）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `ai-analysis-page`：Hub 卡模拟样张、角标、时效位置与功能色文案

## Impact

- 客户端：`ai_analysis_screen.dart`；可能轻触 `FeedingEligibilityProgressText`（可注入 accent）或 Hub 侧包装跟色
- 无服务端 / **BREAKING** API
