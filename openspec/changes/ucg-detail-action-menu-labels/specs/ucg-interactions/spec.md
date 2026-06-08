## ADDED Requirements

### Requirement: Detail time-row action menu pill SHALL show icon with Chinese labels

详情页时间行 `UcgMomentsActionMenu` 展开后的 detached pill MUST 为每个操作项同时展示图标与中文标签，横向排列（图标在左、标签在右）。点赞项标签 MUST 为「点赞」；评论项 MUST 为「评论」；删除项（仅作者可见时）MUST 为「删除」。已赞态 MAY 将心形图标切换为实心并用主题色高亮，但标签文案 MUST 仍为「点赞」。每项整行（图标+标签）MUST 可点击并触发与现有一致的回调；浮层 MUST 保留点外收起行为。

#### Scenario: 非作者展开菜单见点赞与评论标签
- **WHEN** 已登录用户查看他人帖子详情并点击时间行右侧「··」
- **THEN** 浮层 pill SHALL 展示两项：带「点赞」标签的点赞项、带「评论」标签的评论项
- **AND** pill SHALL NOT 展示删除项

#### Scenario: 作者展开菜单见三项标签
- **WHEN** 作者查看自己的帖子详情并点击时间行右侧「··」
- **THEN** 浮层 pill SHALL 展示三项：「点赞」「评论」「删除」，均含对应图标与中文标签

#### Scenario: 点击带标签的操作项
- **WHEN** 用户点击浮层中带标签的任一项
- **THEN** App SHALL 收起浮层并执行对应操作（点赞/打开评论/确认删除动态）

## MODIFIED Requirements

### Requirement: Post detail SHALL use immersive chromeless layout with blurred background

`UcgPostDetailScreen` SHALL NOT use a standard Material AppBar or bottom TabBar. The page SHALL render a full-bleed blurred background derived from theme shell color, first post image, or video poster/thumbnail. Post content SHALL NOT sit inside a rounded card container. Top overlay SHALL provide: back control, author avatar, nickname, and follow pill (solid primary **关注** vs outlined **已关注** styles). A time/IP row SHALL align「···」to the far right opening a detached Like/Comment/Delete floating pill with **icon + Chinese label** per action (see labeled action menu requirement). Square feed and 我的动态 MUST share this single detail implementation.

#### Scenario: 无 AppBar 沉浸式详情
- **WHEN** 用户从广场或我的动态进入帖子详情
- **THEN** 页面 SHALL 无传统 AppBar/TabBar 且背景为模糊图/主题色

#### Scenario: 顶栏关注 pill
- **WHEN** 已登录用户查看他人帖子详情且未关注作者
- **THEN** 顶栏 SHALL 展示实心「关注」pill；已关注时 SHALL 展示「已关注」浅色描边样式

#### Scenario: 时间行菜单
- **WHEN** 用户点击详情页时间行右侧「···」
- **THEN** App SHALL 展示带中文标签（点赞、评论、及作者时的删除）的 Like/Comment/Delete 浮层 pill
