## ADDED Requirements

### Requirement: Post detail SHALL use immersive chromeless layout with blurred background

`UcgPostDetailScreen` SHALL NOT use a standard Material AppBar or bottom TabBar. The page SHALL render a full-bleed blurred background derived from theme shell color, first post image, or video poster/thumbnail. Post content SHALL NOT sit inside a rounded card container. Top overlay SHALL provide: back control, author avatar, nickname, and follow pill (solid primary **关注** vs outlined **已关注** styles). A time/IP row SHALL align「···」to the far right opening a detached Like/Comment floating pill (same dismiss-on-outside behavior as legacy Moments menu). Square feed and 我的动态 MUST share this single detail implementation.

#### Scenario: 无 AppBar 沉浸式详情
- **WHEN** 用户从广场或我的动态进入帖子详情
- **THEN** 页面 SHALL 无传统 AppBar/TabBar 且背景为模糊图/主题色

#### Scenario: 顶栏关注 pill
- **WHEN** 已登录用户查看他人帖子详情且未关注作者
- **THEN** 顶栏 SHALL 展示实心「关注」pill；已关注时 SHALL 展示「已关注」浅色描边样式

#### Scenario: 时间行菜单
- **WHEN** 用户点击详情页时间行右侧「···」
- **THEN** App SHALL 展示 Like/Comment 浮层 pill

## MODIFIED Requirements

### Requirement: MVP interactions SHALL include like, comment, delete own comment, long-press undo own like

The app SHALL support liking posts, commenting from **detail page** (and via detail overflow menu), deleting own comments, and follow/unfollow on detail header. Feed cards SHALL expose direct heart tap for like/unlike without opening detail. Long-press undo own like on feed heart MAY remain or map to double-tap; detail heart SHALL toggle like. Block and report MUST NOT be included in MVP.

#### Scenario: 详情页点赞
- **WHEN** 已登录用户在详情页点击心形或 overflow 中 Like
- **THEN** App SHALL 调用 `POST/DELETE /posts/{id}/like` 并更新 UI

#### Scenario: Feed 卡片快捷点赞
- **WHEN** 已登录用户在广场卡片点击心形
- **THEN** App SHALL 调用 like API 且 SHALL NOT 要求进入详情

#### Scenario: 详情页评论
- **WHEN** 已登录用户在详情页通过 overflow Comment 或底部输入框提交评论
- **THEN** App SHALL 调用 `POST /posts/{id}/comments` 并 append 至全量评论列表

#### Scenario: 删除自己的评论
- **WHEN** 用户在本人评论上触发删除
- **THEN** App SHALL 调用 `DELETE /comments/{commentId}` 并从列表移除

### Requirement: Feed posts SHALL expose likedByMe for authenticated viewers

When feed or `GET /posts/{id}` carries logged-in wxId, responses SHALL include `likedByMe` per post. Client SHALL drive feed card heart and detail heart highlight from this field after load/reload.

#### Scenario: 已登录重新进入广场
- **WHEN** 已登录用户点赞后重新加载 Feed 或详情
- **THEN** UI SHALL 展示已赞态心形

### Requirement: Detail page SHALL show full liker avatars without count and full comments without folding

`UcgPostDetailScreen` SHALL load and display **all** likers (paginated API loop until complete or safe cap) as an avatar grid beside a heart icon reflecting viewer `likedByMe`. The section SHALL NOT display numeric like count text. The heart icon SHALL vertically align with the **first row** of liker avatars. Comments SHALL list **all** items without「展开/折叠」header or five-line default cap. There SHALL be no「共 N 条评论」title row.

#### Scenario: 详情点赞区无数量
- **WHEN** 用户打开有点赞的帖子详情
- **THEN** UI SHALL 展示心形与点赞者头像且 SHALL NOT 展示「N 人」或 likeCount 文案

#### Scenario: 心形与首行头像垂直居中
- **WHEN** 点赞头像网格多行换行
- **THEN** 心形 SHALL 与首行头像垂直居中对齐

#### Scenario: 评论全量展示
- **WHEN** 帖子评论数大于 5
- **THEN** 详情页 SHALL 默认展示全部评论且无折叠控件

### Requirement: Long-press comment SHALL prefill reply with @nickname

On detail page, long-pressing a comment SHALL open the comment composer with text prefilled `@${authorNickname} ` (trailing space) for reply. User MAY edit before send. Mention text SHALL be included in `POST /posts/{id}/comments` body for server mention parsing.

#### Scenario: 长按评论回复
- **WHEN** 用户在详情页长按某条评论
- **THEN** App SHALL 弹出输入框且内容预填 `@该评论者昵称 `

### Requirement: Post author SHALL delete own post from detail only

Delete post control SHALL appear on detail page only when viewer is post author. Feed cards SHALL NOT expose delete. Successful delete SHALL pop detail and invalidate feed providers.

#### Scenario: 作者删除帖子
- **WHEN** 作者在详情页点击删除并确认
- **THEN** App SHALL 调用 `DELETE /posts/{id}` 并返回上一页

#### Scenario: 非作者无删除
- **WHEN** 非作者查看详情
- **THEN** UI SHALL NOT 展示删除按钮

## REMOVED Requirements

### Requirement: Feed engagement block SHALL show liker avatar grid

**Reason**: 广场 Feed 卡片移除 liker 预览；详情页承担全量点赞展示。

**Migration**: 见 `ucg-square-feed` 与详情点赞区需求。
