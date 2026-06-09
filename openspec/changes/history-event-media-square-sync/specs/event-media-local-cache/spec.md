## ADDED Requirements

### Requirement: 同步关闭时 MUST 本地复制媒体

When sync is OFF, the client SHALL copy selected media files into the app documents directory and persist a history-id-to-local-paths mapping. Re-edit MUST support replace, delete, and reorder against local copies.

当「同步广场」关闭时，客户端 MUST 将所选媒体复制到应用 documents 目录，并 MUST 持久化 history id → 本地路径映射。再次编辑时 MUST 支持替换、删除与重排本地副本。

#### Scenario: 首次本地保存

- **WHEN** 用户保存且同步关闭且含至少 1 个新媒体文件
- **THEN** 客户端 MUST 将文件复制到 `documents/history_media/{historyId}/` 并写入 `EventMediaLocalStore` 映射

#### Scenario: 再次打开回显本地媒体

- **WHEN** 用户打开编辑 Sheet、记录无 `postId` 且本地映射存在
- **THEN** 客户端 MUST 从本地路径加载缩略图并展示在横向条带

#### Scenario: 编辑替换移除旧文件

- **WHEN** 用户在本地模式下删除某媒体并保存
- **THEN** 客户端 MUST 从映射移除该项并 MUST 删除对应磁盘文件

### Requirement: 设置页 MUST 提供定向清理

Settings SHALL expose an action to clear history event local media cache only: delete copied files under `history_media/` and remove all `EventMediaLocalStore` keys. It MUST NOT invoke full `feedRepository.clearCache()`.

设置中心 MUST 提供「清除历史媒体缓存」操作：删除 `history_media/` 下复制的文件并清空全部 event→path 映射。**不得**调用 `feedRepository.clearCache()` 全量清缓存。

#### Scenario: 确认清理本地媒体

- **WHEN** 用户在设置页确认「清除历史媒体缓存」
- **THEN** 客户端 MUST 删除本地复制的历史媒体文件与映射，且 MUST NOT 清除喂养历史 list 磁盘缓存或 UCG feed 全量缓存

#### Scenario: 清理后编辑回显

- **WHEN** 用户清理后打开曾仅本地缓存的历史记录
- **THEN** 媒体条带 MUST 为空（备注等非媒体字段不受影响）
