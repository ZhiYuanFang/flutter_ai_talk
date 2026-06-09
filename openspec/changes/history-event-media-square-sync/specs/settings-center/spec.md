## ADDED Requirements

### Requirement: 设置中心 MUST 提供历史媒体缓存清理

The settings center SHALL expose a "清除历史媒体缓存" action with confirmation that clears only local history event media copies and mappings per `event-media-local-cache`.

设置中心 MUST 提供「清除历史媒体缓存」入口，经用户确认后仅清理本地历史事件媒体副本与路径映射（见 `event-media-local-cache`）。

#### Scenario: 从设置进入清理

- **WHEN** 用户在设置中心点击「清除历史媒体缓存」
- **THEN** 系统 MUST 展示确认对话框，说明将删除本机复制的历史媒体且不影响广场帖子

#### Scenario: 确认后执行清理

- **WHEN** 用户确认清理
- **THEN** 系统 MUST 调用 `EventMediaLocalStore` 全量清理逻辑，且 MUST NOT 调用 `feedRepository.clearCache()`
