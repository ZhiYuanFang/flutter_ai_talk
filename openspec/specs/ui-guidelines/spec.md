# UI 设计规范 (UI Guidelines)

## ADDED Requirements

### Requirement: 统一玻璃拟态视觉风格
App **MUST** 保持整体一致的玻璃拟态（Glassmorphism）视觉风格。所有主要的浮层、对话框、卡片应遵循现有的透明度、模糊度（BackdropFilter）及光影设计。

#### Scenario: 新增对话框或面板
- **WHEN** 开发者新增 UI 对话框或底部弹窗。
- **THEN** 必须优先复用 `app_glass_overlay.dart` 中的通用组件，确保模糊边框与阴影一致。

### Requirement: 颜色随系统主色调自适应
UI 元素的辅助色（Accent）和交互颜色 **MUST** 遵循系统当前的主色调（Main/Primary Color）。

#### Scenario: 确认按钮样式
- **WHEN** 渲染确认类按钮。
- **THEN** 必须使用 `Theme.of(context).colorScheme.primary` 作为背景色。
