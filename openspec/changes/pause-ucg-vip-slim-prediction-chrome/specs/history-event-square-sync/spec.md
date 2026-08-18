## ADDED Requirements

### Requirement: Temporary pause gate SHALL hide square-sync toggle and forbid UCG post side effects

While the temporary history square-sync pause gate is active, the history edit sheet MUST NOT show the「同步广场」toggle even when media is selected. Save MUST treat sync as OFF regardless of any stored per-record preference. The client MUST still persist media to the local documents cache per `event-media-local-cache` when media is present. The client MUST NOT call `createPost`, `updatePost`, or `deletePost` (or equivalent UCG publish/update/delete) as a result of saving from the edit sheet under this pause gate.

历史同步广场暂停闸门开启时，编辑 Sheet **即使已选媒体也 MUST NOT** 展示「同步广场」开关；保存 **必须** 按同步关闭处理（忽略本地曾存 ON）；有媒体时仍 **必须** 写入本地缓存；**不得** 因本次保存调用 UCG 发帖/更新/删帖。

#### Scenario: 有图也不展示开关

- **WHEN** 暂停闸门开启且用户已为记录选择至少一张图片或视频
- **THEN** Sheet MUST NOT 展示「同步广场」开关

#### Scenario: 保存不发帖只本地缓存

- **WHEN** 暂停闸门开启、记录含新媒体且用户保存成功
- **THEN** 客户端 MUST 将媒体写入本地 documents 映射
- **AND** MUST NOT 调用 `createPost` / `updatePost`

#### Scenario: 曾有 postId 暂停期保存不删帖

- **WHEN** 暂停闸门开启且记录已有关联 `postId`，用户保存（无法操作开关）
- **THEN** 客户端 MUST NOT 仅因暂停期强制 sync=OFF 而调用 `deletePost`

## MODIFIED Requirements

### Requirement: 「同步广场」开关 MUST 默认关闭、需有媒体才可开启且本地持久化

When the temporary square-sync pause gate is **inactive**, the history edit sheet SHALL show a compact "同步广场" toggle vertically centered to the left of the save button, with a small label below the switch, only when at least one image or video is selected. Default MUST be OFF when no stored preference exists. The toggle MUST be hidden entirely when no image or video is selected; the user MUST NOT be able to turn sync ON without media. When the user removes all media, sync MUST auto-turn OFF and the toggle MUST be hidden. Preference MUST persist locally per history record id using SharedPreferences (pattern like `EventRemarkMemoryStore`). On save, if sync is ON but media is empty, the client MUST treat sync as OFF (defensive). When opening a record with no media, stored ON preference MUST be forced OFF until media is added. When the pause gate is **active**, the ADDED pause-gate requirement supersedes this toggle visibility and sync-on behavior.

当暂停闸门**关闭**时，行为与基线一致（有媒体才展示开关、默认关、本地持久化等）。暂停闸门**开启**时，以本 change 的暂停闸门 Requirement 为准。

#### Scenario: 闸门关闭且有媒体可展示开关

- **WHEN** 暂停闸门关闭且用户已选至少一张图片或视频
- **THEN** 「同步广场」开关 MUST 展示且无已存偏好时默认为关闭

#### Scenario: 闸门关闭且无媒体不展示

- **WHEN** 暂停闸门关闭且未选择图片或视频
- **THEN** 「同步广场」开关 MUST NOT 展示
