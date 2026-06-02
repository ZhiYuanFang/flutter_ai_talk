# home-immersive-header-no-appbar 提案

## Why

当前主页使用标准 `AppBar`，在浅色主题下会形成明显的顶部色块，与下方「今日摘要 + 历史内容」产生割裂，和产品期望的柔和沉浸感不一致。需要将主页头部改为无 `AppBar` 的沉浸式布局，使顶部操作区与内容背景自然衔接，并保持趋势/设置入口可达。

## What Changes

- 主页移除标准 `Scaffold.appBar`，改为页面内自绘沉浸式顶部操作行（返回可选、标题居中、右侧功能入口）。
- 顶部操作行与内容区共用同一背景语义（`shellColor`/渐变），不得出现独立顶栏色块。
- 主页首屏内容（绑定横幅、今日摘要、历史区）调整顶部留白与层级，确保与状态栏安全区自然衔接。
- 保留现有趋势与设置导航能力，入口从 `AppBar.actions` 迁移到沉浸式顶部操作区。
- 不改变历史 WebSocket 横幅、底部输入模块、记录列表与交互数据流。

## Capabilities

### New Capabilities

- `home-immersive-header`: 定义主页无 `AppBar` 的沉浸式头部结构、导航入口位置与头部-内容衔接规则。

### Modified Capabilities

- `home-shell-visual-style`: 补充主页顶部区域与内容区的一体化视觉要求，明确不得出现独立顶栏分色块。

## Impact

- `app/lib/ui/home_screen.dart`（移除 `AppBar`，新增沉浸式头部行并调整布局间距）
- 可能新增 `app/lib/ui/home_immersive_header.dart`（封装顶部操作行）
- 可能调整 `app/lib/theme/app_theme_scope.dart`（避免主页被全局 `AppBarTheme` 视觉牵引）
- `openspec/changes/home-immersive-header-no-appbar/specs/**`（新增/修改需求规格）
