## ADDED Requirements

### Requirement: 顶部居中轻提示位置

The client MUST show transient user messages as a floating hint centered horizontally below the top safe area. 所有「Toast 类」短时文案反馈**必须**以悬浮轻提示形式展示在屏幕**水平正中**、**顶部安全区下方**（约 12 logical px 间距），**不得**使用默认底部 SnackBar 位置。

#### Scenario: 展示位置

- **WHEN** 调用方触发任意 Toast 类提示
- **THEN** 提示容器必须在顶部安全区之下、水平居中，且不得遮挡底部输入主操作区为首选布局

### Requirement: 圆角雾面视觉

The hint MUST use a rounded frosted-glass style background with very low opacity. 轻提示**必须**使用**圆角**（约 12 logical px）容器；背景**必须**为「几乎看不见」的雾面（主题前景或 shell 色 **约 8–12% 不透明度** 或等效 alphaBlend），**不得**使用实心 Material 默认 SnackBar 色块。

#### Scenario: 雾面背景

- **WHEN** 轻提示显示
- **THEN** 用户应能透过背景隐约看到后方内容，且正文在深色/浅色 shell 上均清晰可读

#### Scenario: 文字样式

- **WHEN** 轻提示显示
- **THEN** 正文**必须**使用主题 `onShell`（或等价前景语义色），**不得**硬编码与当前主题无关的固定色

### Requirement: 停留时长分档

The system MUST dismiss success or informational hints after 1 second and error hints after 2 seconds. **成功/信息类**提示**必须**在 **1 秒**内自动消失；**错误类**提示**必须**在 **2 秒**内自动消失。

#### Scenario: 信息类 1 秒

- **WHEN** 提示为成功或中性信息（如「已记录」「已保存」）
- **THEN** 可见时长**必须**为 1s（1000ms）量级

#### Scenario: 错误类 2 秒

- **WHEN** 提示为错误（API 业务失败、网络异常、表单校验失败等）
- **THEN** 可见时长**必须**为 2s（2000ms）量级

### Requirement: 统一入口与顶替

The client MUST route all transient toast messages through a single API and MUST replace any currently visible hint. 所有 Toast 类反馈**必须**经统一 API（如 `showAppToast`）展示；新提示出现时**必须**关闭当前未消失的提示，**不得**多条堆叠。

#### Scenario: apiToast 通路

- **WHEN** `apiToastProvider`（或等价总线）收到非空文案
- **THEN** 必须通过统一顶部轻提示展示，而非默认 `SnackBar(content: Text)` 底部样式

#### Scenario: 连点顶替

- **WHEN** 用户短时间内连续触发多条提示
- **THEN** 仅显示最新一条（旧条被顶替或清除）

### Requirement: 迁移范围

All previous short SnackBar usages for user feedback MUST be migrated except modal dialogs. 原先各页面直接 `ScaffoldMessenger.showSnackBar` 的**短时文案****必须**迁移至本轻提示；**Dialog**、版本更新弹窗等**不在**本需求范围内。

#### Scenario: 主页与仓储

- **WHEN** Repository 或主页通过 toast 总线提示错误/成功
- **THEN** 必须使用本顶部轻提示及对应 tone 时长
