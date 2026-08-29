## REMOVED Requirements

### Requirement: Temporary pause gate SHALL hide square-sync toggle and forbid UCG post side effects

**Reason**: `commercial-ucg-feature-unlock` 翻回 `kHistorySquareSyncEnabled`，恢复同步广场 UI 与 UCG 发帖副作用。

**Migration**: 以基线「同步广场」开关 Requirement 与本 change 翻回后的闸门关闭态为准；不再适用暂停期强制 sync=OFF。

## MODIFIED Requirements

### Requirement: 「同步广场」开关 MUST 默认关闭、需有媒体才可开启且本地持久化

When `kHistorySquareSyncEnabled` is true, the history edit sheet SHALL show a compact "同步广场" toggle vertically centered to the left of the save button, with a small label below the switch, only when at least one image or video is selected. Default MUST be OFF when no stored preference exists. The toggle MUST be hidden entirely when no image or video is selected; the user MUST NOT be able to turn sync ON without media. When the user removes all media, sync MUST auto-turn OFF and the toggle MUST be hidden. Preference MUST persist locally per history record id. On save, if sync is ON but media is empty, the client MUST treat sync as OFF. When opening a record with no media, stored ON preference MUST be forced OFF until media is added. Save with sync ON MUST run UCG create/update post side effects per existing square-sync rules; local media cache MUST still apply when media is present.

当 `kHistorySquareSyncEnabled` 为 true 时，有媒体才展示「同步广场」开关、默认关、本地持久化；同步开启保存时 **必须** 按既有规则触发 UCG 发帖/更新副作用。

#### Scenario: 闸门翻回后有媒体可展示开关

- **WHEN** `kHistorySquareSyncEnabled` 为 true 且用户已选至少一张图片或视频
- **THEN** 「同步广场」开关 MUST 展示且无已存偏好时默认为关闭

#### Scenario: 同步开启可发帖

- **WHEN** 开关为 ON、记录含媒体且用户保存成功
- **THEN** 客户端 MUST 允许走 UCG create/update 同步路径（并仍可写本地媒体缓存）
