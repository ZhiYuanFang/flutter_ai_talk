## ADDED Requirements

### Requirement: 主题预设选择 UI

The settings screen SHALL offer selectable **theme presets** including **「夜空」** alongside existing light swatches and custom color entry. 设置页「主题」区必须提供可点选的**主题预设**（至少包含 **经典默认**、**夜空** 及原有浅色色块）；必须保留进入完整颜色选择器的入口；选中态必须有可见反馈（描边/勾选等）。

#### Scenario: 选择夜空预设

- **WHEN** 用户点击「夜空」预设
- **THEN** 必须立即应用 shell 参考色 `#1A1C24` 的 bundle，持久化 preset 标识与种子色，且主页无需重启即可反映新主题

#### Scenario: 选择经典默认

- **WHEN** 用户点击「经典默认」或执行清除自定义
- **THEN** 必须移除自定义背景与 preset，恢复 classic light bundle

### Requirement: 夜空 preset bundle 定义

The **「夜空」** preset MUST use shell color `#1A1C24`, set `isDarkShell` to true, and derive surface/pill tokens from that bundle per design. **「夜空」**预设必须：`shellColor == #1A1C24`、`isDarkShell == true`；surface/pill 等子层必须按 design 从该 bundle 派生，不得与经典浅色混用同一 surface 色。

#### Scenario: 夜空持久化后再启动

- **WHEN** 用户曾选择夜空并冷启动应用
- **THEN** 必须从本地存储恢复夜空 bundle，且设置页夜空项为选中态

### Requirement: 纯黑预设合并迁移

The client MUST NOT offer standalone pure black `#000000` as a separate preset; existing persisted `#000000` SHALL migrate to the night sky preset. 颜色预设列表**不得**再单独展示纯黑 `#000000` 色块；若本地已存 `Color(0xFF000000)`，下次启动或打开设置时必须**迁移**为「夜空」等价 bundle（种子 `#1A1C24` + preset id），并写回存储。

#### Scenario: 老用户纯黑背景

- **WHEN** 升级前用户保存的背景为 `#000000`
- **THEN** 升级后必须视为已选「夜空」，且视觉为 `#1A1C24` shell 而非纯黑全屏

#### Scenario: 新用户 picker 列表

- **WHEN** 用户打开颜色选择器
- **THEN** 预设色块列表中不得包含独立 `#000000` 项（仍可经「更多颜色」选任意色，含近黑）

### Requirement: 自定义色与 preset 互斥标记

When the user picks a custom color from the full picker, the system MUST clear any active preset id; applying a preset MUST write both preset id and seed color. 用户通过完整 picker 选取自定义色时必须清除 preset id；应用 preset 时必须同时写入 **preset id** 与 **种子色** 至持久化层（SharedPreferences 或等价）。

#### Scenario: preset 后改自定义

- **WHEN** 用户已选夜空后又从 picker 选其它颜色
- **THEN** preset id 必须清除，主题按自定义色规则（含 HSL 深色推导）生效，设置页夜空不再显示选中

#### Scenario: 自定义后再选 preset

- **WHEN** 用户已自定义颜色后点击某一 preset
- **THEN** 必须覆盖自定义色与 preset id，以 preset bundle 为准
