# home-immersive-header-no-appbar 任务清单

## 1. 主页头部结构重构

- [x] 1.1 在 `home_screen.dart` 移除 `Scaffold.appBar`，改为 `body` 内沉浸式头部布局
- [x] 1.2 新增 `HomeImmersiveHeader`（或等价内联结构），承载标题与右侧操作入口
- [x] 1.3 将趋势/设置入口从 `AppBar.actions` 迁移到沉浸式头部并保持既有路由行为

## 2. 头部与内容衔接优化

- [x] 2.1 统一头部与内容背景语义（`shellColor`/等价），移除独立顶栏分色块
- [x] 2.2 调整头部与首块内容（绑定横幅/今日摘要/空态）的顶部间距常量，保证衔接一致
- [x] 2.3 校验浅色与深色 shell 下标题与图标可读性，必要时使用 `onShell` 对比兜底

## 3. 回归与验收

- [x] 3.1 验证主页各状态：有记录、无记录、需绑定、WS 断开横幅显示时布局正常
- [x] 3.2 验证趋势与设置入口点击后仍正确导航到 `/trends` 与 `/settings`
- [x] 3.3 运行 OpenSpec 校验并确认变更可进入 apply 阶段（`openspec validate home-immersive-header-no-appbar --strict`）
