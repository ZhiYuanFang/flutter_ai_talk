## ADDED Requirements

### Requirement: Client SHALL load guide videos on Xiaozhi speaker screen

When the user opens the Xiaozhi speaker management screen while logged in, the client SHALL call `GET /cash/app/api/xiaozhi-mcp/guide-videos` with Bearer auth. The client MUST also refresh this list when the screen’s pull-to-refresh runs. The response `list` items MUST be treated as guidance entries with at least `slot`, `title`, and `videoCdnUrl`; `coverCdnUrl` MAY be used as a list cover. Items missing a usable `videoCdnUrl` MUST be omitted from rendering.

进入小智音箱页（已登录）MUST 拉取引导视频清单；下拉刷新 MUST 重拉；无有效 `videoCdnUrl` 的项 MUST NOT 展示。

#### Scenario: Fetch on enter

- **WHEN** 已登录用户进入小智音箱管理页
- **THEN** 客户端 MUST 发起 `GET /cash/app/api/xiaozhi-mcp/guide-videos`

#### Scenario: Refresh reloads list

- **WHEN** 用户在该页下拉刷新
- **THEN** 客户端 MUST 再次拉取引导视频清单

### Requirement: Empty or failed guide list SHALL hide all guide entries

When the guide-videos `list` is empty after a successful response, OR when the request/parse fails, the client MUST NOT render any guide-video entry UI (including placeholders for「了解能力 / 绑定教学」). Fetch failure MUST be treated the same as an empty list for entry visibility (MUST NOT leave a broken entry row). The existing purchase howto help control and「绑定后可以做什么」body copy MUST remain available independently of the guide list.

`list` 空或拉取/解析失败时 MUST 完全不渲染引导视频入口；失败 MUST 视同空列表；购买 `?` 与能力说明正文 MUST 不受影响。

#### Scenario: Empty list hides entries

- **WHEN** GET 成功且 `list` 为空
- **THEN** 「绑定后可以做什么」卡 MUST NOT 展示任何引导视频入口行

#### Scenario: Failure hides entries

- **WHEN** GET 失败或响应无法解析
- **THEN** 客户端 MUST NOT 展示引导视频入口，且 MUST NOT 以破损占位代替

### Requirement: Guide entries SHALL appear at bottom of capability glass card

When at least one valid guide item exists, the client SHALL render those entries at the **bottom** of the existing「绑定后可以做什么」glass panel, below the capability body copy. Each entry MUST display the server-provided `title` (MUST NOT require hard-coded Chinese labels keyed only by `slot` for display). When `coverCdnUrl` is present, the client MAY show it as cover art for the row.

有有效项时 MUST 渲染在能力说明玻璃卡底部；展示 MUST 用服务端 `title`；封面 MAY 用 `coverCdnUrl`。

#### Scenario: Entries under capability copy

- **WHEN** `list` 含两项有效视频
- **THEN** 两行入口 MUST 出现在「绑定后可以做什么」卡内文案下方，且标题分别为各项 `title`

### Requirement: Tapping a guide entry SHALL open fullscreen playback

When the user taps a guide entry, the client SHALL navigate to a fullscreen playback surface that plays that item’s `videoCdnUrl`. The playback route MUST require login consistently with the Xiaozhi speaker management routes. The client MUST dispose the player when leaving the playback surface.

点击入口 MUST 进全屏播放 `videoCdnUrl`；路由 MUST 要求登录；离开 MUST dispose 播放器。

#### Scenario: Open fullscreen player

- **WHEN** 用户点击某引导项且 `videoCdnUrl` 非空
- **THEN** 客户端 MUST 打开全屏播放页并尝试播放该 URL

#### Scenario: Login gate on playback route

- **WHEN** 未登录用户试图打开引导播放路由
- **THEN** 客户端 MUST 按与小智音箱页一致的登录门禁处理
