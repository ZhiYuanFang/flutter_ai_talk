## ADDED Requirements

### Requirement: Baby avatar SHALL be copied into an app-private local folder

When the user picks a local image for the baby avatar, the client SHALL copy that image into an app-private folder under the application documents tree (e.g. `baby_avatar/`) keyed by baby id, and SHALL persist a reference (relative path or store mapping) for subsequent display. The client MUST NOT rely solely on the transient picker URI.

用户选择宝宝头像后，客户端 **必须** 将图片复制到应用私有目录（如 `documents/baby_avatar/`）并按宝宝 id 管理，且 **必须** 持久化引用；**不得** 仅依赖系统选择器临时 URI。

#### Scenario: 选图后本地可复现

- **WHEN** 用户在编辑页从相册选择一张图片并保存（或选图即落盘的等价流程）
- **THEN** 应用私有 `baby_avatar`（或等价）目录下 MUST 存在该宝宝的本地副本
- **AND** 重启 App 后预测顶栏与编辑页 MUST 仍能展示该头像

### Requirement: Clearing history media cache MUST NOT delete baby avatar

Invoking settings「清除历史媒体缓存」（`EventMediaLocalStore.clearAll` or equivalent) MUST delete local history event media under `history_media/` (or equivalent) and MUST NOT delete baby avatar files under the baby avatar store directory.

清除历史媒体缓存 **必须** 只清理历史事件媒体；**不得** 删除宝宝头像本地文件。

#### Scenario: 清缓存后头像仍在

- **WHEN** 用户已设置本地宝宝头像，并在设置中确认清除历史媒体缓存
- **THEN** 历史事件本地图片/视频 MUST 被清理
- **AND** 宝宝头像本地文件 MUST 仍存在且 UI 仍可展示

### Requirement: Default baby avatar SHALL use sex-colored placeholder

When no local baby avatar file is available, the UI SHALL show a default avatar placeholder: male MUST use a blue tint, female MUST use a pink tint, and unknown sex MUST use a neutral gray. Colors SHOULD align with `BabyProfileClayTheme` accents when present.

无本地头像时 **必须** 展示默认占位：男蓝、女粉、未知中性灰。

#### Scenario: 男宝默认蓝

- **WHEN** 宝宝性别为男且无本地头像文件
- **THEN** 头像占位 MUST 呈现蓝色系（非粉）

#### Scenario: 女宝默认粉

- **WHEN** 宝宝性别为女且无本地头像文件
- **THEN** 头像占位 MUST 呈现粉色系（非蓝）

#### Scenario: 未知性别中性灰

- **WHEN** 宝宝性别为 unknown 且无本地头像文件
- **THEN** 头像占位 MUST 使用中性灰色系
