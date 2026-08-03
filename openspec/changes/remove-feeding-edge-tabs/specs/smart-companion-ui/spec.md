## MODIFIED Requirements

### Requirement: Immersive home header MUST remove clinic entry

The feeding immersive header MUST NOT provide a control that opens the legacy clinic route (`/pangbao`) as the primary companion entry. 喂养沉浸式头部 **不得** 再提供进入原诊疗路由的主入口。

#### Scenario: 顶栏无诊疗入口

- **WHEN** 用户查看喂养页沉浸式头部
- **THEN** UI MUST NOT 展示可 `push('/pangbao')` 的诊疗/陪伴图标入口（进入陪伴改由 PageView 横滑 / 小贴士「对话」等，**不得** 再依赖喂养页贴边拉条）
