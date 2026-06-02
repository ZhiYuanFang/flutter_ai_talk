# home-shell-visual-style 变更规格

## MODIFIED Requirements

### Requirement: 主页 Scaffold 使用 shell 令牌

The home screen Scaffold background MUST use `AppVisualTokens.shellColor` and SHALL avoid any standalone AppBar color block. 主页 `Scaffold`（及同等最外层容器）背景必须使用 **`AppVisualTokens.shellColor`**，并且在主页顶部不得渲染独立 `AppBar` 分色块；顶部操作区必须与内容区共用 shell 背景语义。

#### Scenario: 切换至夜空后主页背景

- **WHEN** 用户启用夜空或深色 shell bundle 并进入主页
- **THEN** 主页最外层背景必须与 `tokens.shellColor` 一致，且与历史列表区域分层可见

#### Scenario: 主页顶部沉浸式展示

- **WHEN** 用户进入主页并查看状态栏下方头部区域
- **THEN** 头部操作区必须与内容区域连续衔接
- **AND** 不得出现独立顶栏色块或默认 `AppBar` 背景
