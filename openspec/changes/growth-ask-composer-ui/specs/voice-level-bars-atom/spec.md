## ADDED Requirements

### Requirement: VoiceLevelBars SHALL be a reusable accent-driven energy meter

The client MUST provide a shared voice level bars widget that renders a multi-bar energy meter from a normalized level in `[0,1]`. Callers MUST be able to supply an accent color for active bars and a cancelled visual state. The widget MUST NOT hard-depend on Home-only theme roles as its only accent source. 客户端 **必须** 提供可复用的语音能量柱组件；**必须** 支持传入 accent 与取消态；**不得** 仅能使用首页 primary 作为唯一着色来源。

#### Scenario: Accent bars at mid level

- **WHEN** 调用方传入 `level≈0.5` 与非空 accent 且 `cancelled=false`
- **THEN** 组件 MUST 以 accent 系颜色绘制多柱，高度随 level 与柱系数变化

#### Scenario: Cancelled state

- **WHEN** `cancelled=true`
- **THEN** 组件 MUST 使用错误/取消语义色系（非普通 accent 高亮）绘制柱条
