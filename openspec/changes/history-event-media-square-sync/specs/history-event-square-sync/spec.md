## ADDED Requirements

### Requirement: 「同步广场」开关 MUST 默认关闭、需有媒体才可开启且本地持久化

The history edit sheet SHALL show a compact "同步广场" toggle vertically centered to the left of the save button, with a small label below the switch, only when at least one image or video is selected. Default MUST be OFF when no stored preference exists. The toggle MUST be hidden entirely when no image or video is selected; the user MUST NOT be able to turn sync ON without media. When the user removes all media, sync MUST auto-turn OFF and the toggle MUST be hidden. Preference MUST persist locally per history record id using SharedPreferences (pattern like `EventRemarkMemoryStore`). On save, if sync is ON but media is empty, the client MUST treat sync as OFF (defensive). When opening a record with no media, stored ON preference MUST be forced OFF until media is added.

历史编辑 Sheet 在用户已选至少一张图片或一条视频时，必须在保存按钮**左侧**、垂直居中展示「同步广场」小号 Switch，下方展示小字标签「同步广场」。无已存偏好时默认 MUST 为**关闭**。未选择图片或视频时 MUST 完全隐藏「同步广场」开关；用户 MUST NOT 在无媒体时开启同步。用户移除全部媒体后同步 MUST 自动关闭且开关 MUST 隐藏。开关状态 MUST 按 **history 记录 id** 本地持久化（SharedPreferences，模式同 `EventRemarkMemoryStore`）。保存时若同步为开但无媒体，客户端 MUST 按关闭处理（防御性）。打开无媒体记录时，即使本地曾存为开也 MUST 强制为关，直至用户添加媒体。

#### Scenario: 首次打开无本地记录

- **WHEN** 用户首次打开某条历史的编辑 Sheet 且无已存开关偏好
- **THEN** 「同步广场」MUST 默认为关闭

#### Scenario: 再次打开恢复偏好

- **WHEN** 用户曾开启某 history id 的同步开关、该记录含媒体并保存偏好
- **THEN** 再次打开该记录编辑 Sheet 时开关 MUST 恢复为开启状态

#### Scenario: 无媒体时开关隐藏

- **WHEN** 编辑 Sheet 中 `_media` 为空
- **THEN** 「同步广场」开关 MUST NOT 展示

#### Scenario: 添加首个媒体不自动开启

- **WHEN** 用户从无媒体状态添加第一张图片或视频
- **THEN** 开关 MUST 展示且 MUST 变为可交互，且 MUST NOT 自动开启（除非用户手动拨动）

#### Scenario: 移除全部媒体自动关闭

- **WHEN** 用户删除最后一条媒体
- **THEN** 同步开关 MUST 自动关闭并 MUST 隐藏

#### Scenario: 打开无媒体记录强制关闭

- **WHEN** 用户打开一条无媒体的记录，且本地偏好曾为开启
- **THEN** 开关 MUST 隐藏，直至用户添加媒体

### Requirement: 同步开启保存 MUST 发布或更新 UCG 帖子

When sync is ON and JWT `sub` is non-zero, save MUST compress media to UCG limits, upload via presign pipeline, and call `createPost` (no `postId`) or `updatePost` (existing `postId`) with a formatted post caption: line 1 `{babyName}的{eventName}`, line 2 the remark when non-empty (joined by `\n`). Baby name MUST come from settings baby profile nickname; event name MUST prefer event catalog lookup by `eventId`, else `HistoryRecord.eventName`, with empty resolving to `未知事件`. When baby nickname is missing or placeholder (`未绑定宝宝ID` / `待设置`), line 1 MUST use `宝宝` as `{babyName}`.

当「同步广场」开启且 JWT `sub≠0`（wx.id）时，保存 MUST 将媒体压缩至 UCG 限制、经 presign/upload 管道上传，并无 `postId` 时调用 `createPost`、有 `postId` 时调用 `updatePost`，帖子正文 MUST 格式化为：第一行 `{宝宝名}的{事件名}`，备注非空时第二行为备注（`\n` 连接）。宝宝名 MUST 取自设置宝宝画像 nickname；事件名 MUST 优先按 `eventId` 查事件目录，否则用 `HistoryRecord.eventName`，空则 `未知事件`。宝宝 nickname 缺失或为占位（`未绑定宝宝ID` / `待设置`）时，第一行 MUST 以 `宝宝` 作为 `{宝宝名}`。

#### Scenario: 首次同步发帖

- **WHEN** 用户保存且同步开启、`postId` 为空、已选媒体且 `sub≠0`
- **THEN** 客户端 MUST 上传媒体并调用 `createPost`，成功后 MUST 将返回的 `postId` 合并进本地历史记录

#### Scenario: 再次编辑已同步记录

- **WHEN** 用户保存且同步开启、记录含非空 `postId`、已调整媒体或备注
- **THEN** 客户端 MUST 调用 `updatePost` 更新对应帖子

#### Scenario: 同步 caption 含宝宝与事件名

- **WHEN** 用户保存且同步开启、宝宝 nickname 为「小明」、事件名为「喂奶」、备注为「120ml」
- **THEN** `createPost` / `updatePost` 的 `text` MUST 为 `小明的喂奶\n120ml`（第一行 `{宝宝名}的{事件名}`，第二行备注）

#### Scenario: 无备注时 caption 仅一行

- **WHEN** 用户保存且同步开启、备注为空
- **THEN** 帖子 `text` MUST 仅为 `{宝宝名}的{事件名}` 一行，且 MUST NOT 追加空第二行

#### Scenario: sub 为零不得调用 UCG API

- **WHEN** 用户保存且同步开启但 JWT `sub=0`
- **THEN** 客户端 MUST 展示绑定微信提示，且 MUST NOT 调用 `createPost` / `updatePost` / `deletePost`

#### Scenario: 不得以 unionid 拦截

- **WHEN** 用户 `sub≠0` 但未绑定 WeChat unionid
- **THEN** 客户端 MUST 允许 UCG 同步流程，且 MUST NOT 因 unionid / `isWxBound` 单独拦截

### Requirement: 曾同步后关闭同步 MUST 删除 UCG 帖子

When the user turns sync OFF and saves a record that previously had a `postId`, the client MUST call `deletePost` and clear the association.

当用户将「同步广场」关闭并保存一条**曾有关联 `postId`** 的记录时，客户端 MUST 调用 `deletePost` 删除 UCG 帖子，并 MUST 清除本地 `postId` 关联。

#### Scenario: 关闭同步删帖

- **WHEN** 用户将同步开关从开改为关并保存成功，且记录原有 `postId`
- **THEN** 客户端 MUST 调用 `deletePost(postId)`，且本地记录 `postId` MUST 置空

#### Scenario: 关闭同步后仅本地缓存

- **WHEN** 用户关闭同步并保存且含新媒体
- **THEN** 客户端 MUST 将媒体写入本地 documents 映射（见 `event-media-local-cache`），且 MUST NOT 创建新 UCG 帖子
