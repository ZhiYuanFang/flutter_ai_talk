## MODIFIED Requirements

### Requirement: 历史行 EventLogo 尺寸 MUST 随 fromBottom 与 base 字号同坡衰减

The home history timeline row EventLogo size MUST scale continuously with the same base font-size decay used for row body text as `fromBottom` increases: larger near the bottom (newest) and smaller toward older rows, without tracking the 1.5× event-name visual multiplier. 主页历史时间轴行 `EventLogo` 尺寸 MUST 与该行正文 **base** `fontSize`（现网 `(13 - fromBottom * 0.35).clamp(9, 13)` 或等价）同比例缩放，例如 `logoSize ≈ 24 * fontSize / 13` 并 clamp 到约 **10–24**；`fromBottom == 0` 时 logo MUST 约为 **24**（相对原 16 锚的 1.5×）。MUST NOT 按事件名 1.5× 字号放大 logo；MUST NOT 仅用「最新 / 非最新」两档替代连续衰减。行高约 40、单行布局、点击进详情、停止计时与飞入锚点语义 MUST 保持。

#### Scenario: 最新行 logo 最大

- **WHEN** 渲染 `fromBottom == 0` 的历史行
- **THEN** 该行 `EventLogo` 逻辑边长 MUST 约为 24

#### Scenario: 旧行 logo 小于最新行

- **WHEN** 列表同时展示 `fromBottom == 0` 与较大 `fromBottom` 的行
- **THEN** 较大 `fromBottom` 行的 logo 边长 MUST 小于最新行，且 MUST NOT 低于约 10 逻辑像素

#### Scenario: 不跟事件名 1.5×

- **WHEN** 任意历史行同时渲染事件名（1.5× base）与 EventLogo
- **THEN** logo 尺寸 MUST 由 base `fontSize` / `fromBottom` 与锚 24 推导，MUST NOT 再乘事件名 1.5 系数
