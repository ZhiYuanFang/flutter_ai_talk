## MODIFIED Requirements

### Requirement: 自适应高度与最大屏高比例

The client SHALL limit bottom sheet content height to at most two-thirds of the screen while allowing intrinsic height when content is shorter. 底部 Sheet 内容区最大高度 MUST 不超过屏幕高度的 **2/3**；内容不足时 MUST 随内容高度收缩。

#### Scenario: 短内容

- **WHEN** Sheet 内容高度小于屏高 2/3
- **THEN** Sheet MUST NOT 被强制撑满 2/3 高度

#### Scenario: 长内容

- **WHEN** 内容超过 2/3 屏高
- **THEN** 内容区 MUST 可垂直滚动且外层高度 MUST  cap 在 2/3

### Requirement: 历史编辑 Sheet 透明外层

The home history edit sheet entry MAY use a transparent modal bottom sheet background so an inner glass panel provides the visible chrome. 主页历史编辑 Sheet MUST MAY 使用 **transparent** 的 `showModalBottomSheet` 背景，由内部玻璃卡片承担圆角与填充；**不得**因此破坏其他 Sheet 的默认 Material 背景行为。

#### Scenario: 其他 Sheet 不受影响

- **WHEN** 用户打开事件 catalog、用量添加等非历史编辑 Sheet
- **THEN** 这些 Sheet MUST 继续使用既有 `AppAdaptiveBottomSheet` 默认背景与 drag handle（除非其自身另行指定）
