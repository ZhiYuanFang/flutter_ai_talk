## ADDED Requirements

### Requirement: Album picker SHALL enforce photo-video mutual exclusion at selection time

The custom album picker MUST enforce mutual exclusion while the user selects assets: once the user selects a video, photo cells SHALL become disabled; once the user selects one or more photos, video cells SHALL become disabled. The picker MUST allow at most 9 images OR 1 video per session.

自建相册页必须在选择过程中强制图片与视频互斥：选视频后图片不可选；选图片后视频不可选；最多 9 图或 1 视频。

#### Scenario: 先选图片进入 photo 模式
- **WHEN** 用户在 idle 状态点击一张图片
- **THEN** App SHALL 进入 photo 模式并选中该图
- **AND** 所有视频缩略图格 SHALL 显示为 disabled 且不可点击

#### Scenario: 先选视频进入 video 模式
- **WHEN** 用户在 idle 状态点击一个视频
- **THEN** App SHALL 进入 video 模式并选中该视频
- **AND** 所有图片缩略图格 SHALL 显示为 disabled 且不可点击

#### Scenario: photo 模式满 9 张
- **WHEN** 用户已在 photo 模式选中 9 张图片
- **THEN** 其余未选图片格 SHALL disabled
- **AND** 视频格 SHALL 保持 disabled

#### Scenario: 取消全部选择回 idle
- **WHEN** 用户取消选中所有已选资产
- **THEN** App SHALL 回到 idle，图片与视频均可再选

### Requirement: Album picker SHALL use glass-styled full-screen UI on native platforms

On iOS and Android,「从手机相册选择」SHALL navigate to a full-screen album picker with glass-styled chrome (top bar with cancel/complete, grid thumbnails). The complete action MUST use `ColorScheme.primary` capsule styling consistent with the compose publish button.

原生平台「从手机相册选择」须进入全屏玻璃风格相册页；完成按钮须使用主题 primary 胶囊样式。

#### Scenario: 相册页完成上传
- **WHEN** 用户在相册页选中至少一项并点击「完成」
- **THEN** App SHALL 上传所选媒体并返回 `UcgComposeInitialMedia`
- **AND** App SHALL 进入 compose 页预填媒体

#### Scenario: 相册页取消
- **WHEN** 用户点击相册页「取消」
- **THEN** App SHALL 返回入口前状态且不进入 compose

### Requirement: Album picker SHALL degrade on Web

On Web, when native album access is unavailable, the app MAY use system `pickMultipleMedia` or equivalent file picker. If the user selects mixed photos and videos, the app MUST reject the selection with a user-visible message and MUST NOT proceed to compose.

Web 平台可降级系统文件选择；若混选图片与视频则须拒绝并提示，不得进入 compose。

#### Scenario: Web 混选拒绝
- **WHEN** Web 降级 picker 返回同时含图片与视频的结果
- **THEN** App SHALL 提示只能选一种类型
- **AND** App SHALL NOT 上传或打开 compose

## MODIFIED Requirements

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

When no local draft exists, short-tap「+」SHALL present a glass-styled bottom sheet with at least「拍摄」and「从手机相册选择」.「拍摄」SHALL support photo capture and video recording via device camera where platform allows.「从手机相册选择」SHALL open the custom album picker on native platforms (NOT a secondary photo-vs-video sheet, NOT raw system picker on native). Mutual exclusion MUST be enforced in the album picker before compose opens.

无草稿时入口须为玻璃 sheet；拍摄支持拍照/录像；相册须进入自建相册页（原生），不得再弹图片/视频二次 sheet。

#### Scenario: 拍摄照片
- **WHEN** 用户在 glass sheet 选择「拍摄」并拍摄照片
- **THEN** App SHALL 上传并进入 compose，预填该图片

#### Scenario: 拍摄视频
- **WHEN** 用户在 glass sheet 选择「拍摄」并录制视频
- **THEN** App SHALL 校验时长与大小后上传并进入 compose，预填该视频

#### Scenario: 相册进入自建页
- **WHEN** 用户在 glass sheet 选择「从手机相册选择」（原生平台）
- **THEN** App SHALL push 全屏自建相册页
- **AND** App SHALL NOT 展示「选择图片 / 选择视频」二次 sheet

#### Scenario: Web 拍摄降级
- **WHEN** 客户端运行在 Web 且相机不可用
- **THEN** App MAY 隐藏或禁用「拍摄」并仅提供相册降级选择
