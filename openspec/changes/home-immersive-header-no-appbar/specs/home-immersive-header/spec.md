# home-immersive-header 变更规格

## ADDED Requirements

### Requirement: 主页使用沉浸式无 AppBar 头部

The home screen MUST render an immersive in-body header instead of `Scaffold.appBar`. 主页必须移除标准 `Scaffold.appBar`，并在 `body` 内渲染沉浸式头部行（标题与操作入口），使头部与内容背景一体化。

#### Scenario: 主页主结构渲染

- **WHEN** 用户进入主页
- **THEN** 页面必须不再创建 `Scaffold.appBar`
- **AND** 页面顶部必须在 `SafeArea` 内显示沉浸式头部行

### Requirement: 沉浸式头部保留趋势与设置入口

The immersive header SHALL preserve top-right navigation actions for Trends and Settings with unchanged routes. 沉浸式头部必须在右侧保留趋势与设置入口，且路由行为必须与现网一致。

#### Scenario: 点击趋势入口

- **WHEN** 用户点击沉浸式头部中的趋势入口
- **THEN** 应用必须导航至 `/trends`

#### Scenario: 点击设置入口

- **WHEN** 用户点击沉浸式头部中的设置入口
- **THEN** 应用必须导航至 `/settings`

### Requirement: 头部与首块内容保持无缝衔接

The system MUST keep a seamless visual transition between immersive header and first content block without a distinct top color band. 系统必须保证沉浸式头部与首块内容之间的视觉连续性，不得出现独立顶栏分色块。

#### Scenario: 浅色 shell 下衔接

- **WHEN** 当前主题为浅色 shell 且主页显示今日摘要或绑定横幅
- **THEN** 头部区域与内容区必须共享同一背景语义
- **AND** 不得出现明显横向分割色带

#### Scenario: 深色 shell 下衔接

- **WHEN** 当前主题为深色 shell
- **THEN** 头部与内容衔接必须保持层次可读
- **AND** 标题与图标前景色必须可读
