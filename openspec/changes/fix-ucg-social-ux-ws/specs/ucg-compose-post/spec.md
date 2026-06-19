## ADDED Requirements

### Requirement: Compose media preview SHALL avoid visible flash after background upload

When a compose or edit-post slot completes background OSS upload, the UI MUST NOT perform a full-screen or full-grid visible flash. The client MUST keep showing the local thumbnail while `objectKey`/`cdnUrl` become available, MUST stabilize grid cell keys per slot id, and MUST refresh only the affected slot until a network image is precached (optional cross-fade).

compose/编辑帖后台上传完成后，界面不得出现明显全屏或整网格闪烁；须优先保持本地缩略图、稳定 cell key、仅刷新受影响 slot，网络图 precache 后再切换（可淡入）。

#### Scenario: 编辑帖加图上传完成不闪

- **WHEN** 用户在编辑动态 compose 页添加本地图片且后台上传在数秒内完成
- **THEN** 九宫格 SHALL 持续展示本地预览而无整页白闪或全网格同时重建
- **AND** 用户 SHALL NOT 感知明显「过了一会闪一下」

#### Scenario: 单格刷新

- **WHEN** 仅一个 slot 的上传状态从 pending 变为 done
- **THEN** App SHALL 仅重建该格或该 slot 的 listenable
- **AND** SHALL NOT 对无关格子重新发起缩略图 Future

#### Scenario: 网络图就绪后切换

- **WHEN** slot 已有本地预览且 CDN URL 可用
- **THEN** App MAY 在 precache 成功后切换为网络图
- **AND** 切换 SHOULD 使用短淡入或无缝替换，不得先空白占位再加载

### Requirement: 新发视频帖选定后不可删除视频

When the user is composing a **new** post (not editing an existing post) and has selected a video, the compose screen MUST NOT offer a control to remove or replace that video. The user MUST exit compose and re-enter to choose different media.

用户新发视频动态时，选定视频后 compose 页不得提供删除/替换视频的控件；须退出后重新进入方可换媒资。

#### Scenario: 新发视频帖无删除按钮

- **WHEN** 用户在无 `editingPost` 的 compose 页已选定视频
- **THEN** 视频预览区 SHALL NOT 显示删除（×）按钮
- **AND** 用户 SHALL 仍可通过点击预览全屏播放

#### Scenario: 视频封面播放按钮与动态列表一致

- **WHEN** 用户在 compose 页预览已选视频封面
- **THEN** 播放按钮 SHALL 使用与动态列表 `UcgInlineVideoPlayer` 相同的图标（`play_circle_filled_rounded`）、主题色半透明样式与 44px 尺寸

#### Scenario: 编辑帖可删除视频

- **WHEN** 用户在编辑已有动态的 compose 页
- **THEN** 若帖含视频，App MAY 保留删除视频控件（与编辑图片行为一致）
