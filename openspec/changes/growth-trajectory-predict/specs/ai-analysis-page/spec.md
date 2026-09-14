## MODIFIED Requirements

### Requirement: AI analysis page SHALL host feeding analysis and growth trajectory modules

The client SHALL provide a dedicated AI analysis route that contains exactly two primary modules stacked vertically: (1) feeding-record analysis (care-alert eligibility / unlock / list / manual refresh) and (2) the growth-trajectory prediction module (unlock / latest result / predict session). The page MUST be reachable from the next-3-hours 「AI分析」 control. The growth-trajectory module MUST NOT remain a non-interactive「即将上线」placeholder once this change is implemented. 客户端 **必须** 提供独立 AI 分析路由，纵向两模块：喂养记录分析与成长轨迹预测；**必须** 可由「接下来3小时」上的「AI分析」进入；成长轨迹 **不得** 再保持无交互浅占位。

#### Scenario: 从预测页进入

- **WHEN** 用户在智能预测页点击「接下来3小时」卡片上的「AI分析」
- **THEN** 客户端 MUST 打开 AI 分析页
- **AND** 页面 MUST 同时展示喂养记录分析模块与成长轨迹预测模块

#### Scenario: 成长轨迹为可交互模块

- **WHEN** 用户打开 AI 分析页
- **THEN** 成长轨迹模块 MUST 按开通与会话状态展示引导、结果或预测 CTA
- **AND** 在已开通需要展示历史结果或进行预测时 MAY 发起成长轨迹相关 HTTP/SSE
- **AND** MUST NOT 仅展示「即将上线」类不可用占位作为唯一内容

## ADDED Requirements

### Requirement: Growth trajectory module on AI analysis page SHALL follow growth-trajectory-predict capability

Behavior of unlock, SSE Q&A, thinking display, daily-limit toasts, and result rendering on the AI analysis page growth module SHALL conform to capability `growth-trajectory-predict`. AI 分析页成长轨迹模块的开通、SSE 问答、思考展示、日限 Toast 与结果渲染 **必须** 符合能力 `growth-trajectory-predict`。

#### Scenario: 规格交叉引用

- **WHEN** 实现或验收 AI 分析页成长轨迹模块
- **THEN** 验收 MUST 同时满足本页布局 Requirement 与 `growth-trajectory-predict` 各 Requirement
