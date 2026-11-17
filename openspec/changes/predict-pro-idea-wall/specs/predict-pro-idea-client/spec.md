## ADDED Requirements

### Requirement: Client SHALL load submit and like predict Pro ideas via device APIs

The Flutter client SHALL provide a repository that calls Go App endpoints under `/device/app/api/predict-pro-ideas/` for `list`, `submit`, `like`, and `unlike` (or documented equivalents) under the logged-in session. List items MUST map at least `id`, `text`, `babyName`, `likeCount`, `likedByMe`, and `isMine`. Automatic list loads MUST use single-flight. After successful submit or like/unlike, the in-wall idea state MUST refresh or update accordingly. 客户端 **必须** 经 App API 拉列表、提交与点赞。

#### Scenario: Load on Pro wall

- **WHEN** 用户打开两档墙并展示 Pro 档
- **THEN** 客户端 MUST 发起（或复用 in-flight）list 请求

#### Scenario: Submit refreshes wall

- **WHEN** 用户在作曲 Sheet 发送成功
- **THEN** 客户端 MUST 关闭 Sheet 并刷新墙内想法展示

### Requirement: Pro ideas empty state SHALL bottom-align a heartbeat circular CTA

When the ideas list is empty (including after a successful empty load), the Pro card MUST show an empty-state layout with a circular「我有想法」control that uses a continuous heartbeat scale animation, bottom-aligned within the card content area (MUST NOT sit stacked immediately under the title when spare vertical space exists). Below the circle the client MUST show the small helper「具备什么功能，你愿意付费开通」。空态 **必须** 底对齐心跳圆钮并挂付费意愿小字。

#### Scenario: Empty bottom dock

- **WHEN** list 为空且 Pro 档可见
- **THEN** UI MUST 在卡内底部展示圆形「我有想法」与指定小字
- **AND** 圆钮 MUST 呈心跳缩放动画

### Requirement: Pro ideas non-empty state SHALL show copy cards likes and more-ideas CTA

When the ideas list is non-empty, the Pro card MUST show：title「可能扩展包含以下能力」；small line「热度越高越可能被收纳进Pro功能中」；another small line「被采纳的意见提供者后续可联系管理者，获取免费开通Pro版1个月的资格」；then idea rows ordered as returned by the server (newest-first). Each row MUST show author label「{babyName}的家长」in smaller text, idea `text` in an indented rectangular background, and a fire-style like control with `likeCount` vertically centered on the author row’s trailing side. Tapping like MUST toggle like/unlike. Below the list the client MUST show button「我有更多想法」and the same付费意愿小字. 有想法时 **必须** 展示约定文案、卡片布局、火赞与「我有更多想法」。

#### Scenario: Card anatomy

- **WHEN** list 含至少一条
- **THEN** 每条 MUST 含「{宝宝名}的家长」、缩进矩形正文、右侧火标热度

#### Scenario: Like toggle

- **WHEN** 用户点某条火标
- **THEN** 客户端 MUST 调用 like 或 unlike 并更新该条热度/已赞态

### Requirement: Client SHALL highlight the current user’s own ideas

When `isMine` is true, the idea row MUST use a distinct accent/highlight color treatment so the user can locate their own ideas at a glance. When `isMine` is false, the row MUST use the default non-highlight treatment. 本人想法 **必须** 颜色高亮。

#### Scenario: Own idea highlighted

- **WHEN** 某条 `isMine==true`
- **THEN** 该条 UI MUST 呈现相对其他条目可分辨的高亮样式

### Requirement: Compose UI SHALL be a new bottom glass sheet that lifts as a whole with the keyboard

Tapping「我有想法」or「我有更多想法」MUST open a **new** modal bottom sheet (glass-styled) for composing an idea; the client MUST NOT replace the tier-wall dialog structure with an in-wall text dock as the primary compose surface. The sheet MUST dock to the bottom by default. When the keyboard is visible, the client MUST lift the **entire sheet** with `viewInsets` (or equivalent), and MUST NOT only pad the TextField while leaving the sheet shell unmoved. The sheet State MUST own and dispose `TextEditingController` (and FocusNode if any). Empty send MUST be disabled or rejected. 作曲 **必须** 为新建底浮玻璃 Sheet；键盘 **必须** 顶整张 Sheet。

#### Scenario: Open sheet from empty CTA

- **WHEN** 用户点空态「我有想法」
- **THEN** 客户端 MUST 打开新建 Sheet 且两档墙仍可在返回后可见

#### Scenario: Keyboard lifts whole sheet

- **WHEN** Sheet 已打开且键盘弹出
- **THEN** Sheet 整体 MUST 上移（非整窗内仅 TextField 单独上移）
