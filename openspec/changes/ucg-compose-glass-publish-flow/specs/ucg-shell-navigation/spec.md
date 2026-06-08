## MODIFIED Requirements

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

When no local draft exists, short-tap「+」SHALL present a **glass-styled** bottom sheet (`showGlassAdaptiveBottomSheet` + `HistoryEditGlassPanel`) with at least「拍摄」and「从手机相册选择」. Camera capture sub-sheet MUST also use glass styling.「从手机相册选择」SHALL navigate to the custom `ucg-album-picker` full-screen page on native platforms.

无草稿时入口 sheet 与拍摄子 sheet 须为玻璃风格；相册须进入自建相册页（见 `ucg-album-picker`）。

#### Scenario: 玻璃入口 sheet
- **WHEN** 用户短按「+」且无草稿
- **THEN** App SHALL 展示玻璃风格 bottom sheet
- **AND** sheet SHALL NOT 使用默认 Material 不透明底

#### Scenario: 玻璃拍摄子 sheet
- **WHEN** 用户选择「拍摄」
- **THEN** App SHALL 展示玻璃风格拍照/录像子选项 sheet

#### Scenario: 相册跳转自建页
- **WHEN** 用户选择「从手机相册选择」（原生）
- **THEN** App SHALL push 自建相册页而非系统 picker 或二次分流 sheet
