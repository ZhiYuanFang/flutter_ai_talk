## ADDED Requirements

### Requirement: 账号管理与设置弹层禁止暴露联调选项
Production UI MUST NOT expose debug or integration-test account actions to end users.

面向用户的设置与账号管理界面不得展示「业务登录校验」「手动输入 jsCode/deviceNo」等联调或后端内部概念选项。若开发构建需要诊断入口，必须限于 `kDebugMode` 或独立 dev flavor，且不得出现在 Release 用户路径。

#### Scenario: Release 设置页账号管理
- **WHEN** 用户在 Release 构建打开账号管理
- **THEN** MUST NOT 展示「业务登录校验（联调）」「绑定设备号」「微信补齐用户名密码」等项
- **AND** MUST NOT 要求用户手动输入 OAuth code

#### Scenario: 用户可见文案使用宝宝ID语义
- **WHEN** 任何用户可见文案涉及绑定宝宝标识
- **THEN** 必须使用「宝宝ID」等产品用语
- **AND** MUST NOT 使用「设备号」「deviceNo」等后端术语

### Requirement: 账号管理 Sheet 必须复用玻璃 overlay 入口
The account management bottom sheet MUST use the shared glass overlay entry defined in app-glass-overlay.

账号管理 BottomSheet 必须通过 `showGlassAdaptiveBottomSheet`（或项目内等价的 `app_glass_overlay` 入口）实现，不得使用默认 Material 实心 bottom sheet。

#### Scenario: 账号管理视觉一致性
- **WHEN** 用户打开账号管理 Sheet
- **THEN** 可见面板 MUST 为 `HistoryEditGlassPanel`（或等价玻璃容器）
- **AND** 遮罩、圆角、模糊参数 MUST 与同应用其他玻璃 Sheet 一致

## MODIFIED Requirements

### Requirement: 统一玻璃拟态视觉风格
App **MUST** 保持整体一致的玻璃拟态（Glassmorphism）视觉风格. All primary overlays, dialogs, and cards SHALL follow existing blur, transparency, and border tokens; account-management and password-change flows are explicitly in scope.

所有主要浮层、对话框、卡片应遵循现有的透明度、模糊度（BackdropFilter）及光影设计；**账号管理 BottomSheet、改密页、改密/绑微信成功确认框均在本规范范围内**。

#### Scenario: 新增对话框或面板
- **WHEN** 开发者新增 UI 对话框或底部弹窗
- **THEN** 必须优先复用 `app_glass_overlay.dart` 中的通用组件，确保模糊边框与阴影一致

#### Scenario: 账号管理改密确认框
- **WHEN** 改密成功或绑定微信成功需向用户确认
- **THEN** 必须使用 `showGlassDialog` 或 `showGlassConfirmDialog`
- **AND** MUST NOT 使用默认 `AlertDialog` 实心 surface
