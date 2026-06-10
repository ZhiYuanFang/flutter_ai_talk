## MODIFIED Requirements

### Requirement: Album picker SHALL use glass-styled full-screen UI on native platforms

On iOS and Android,「从手机相册选择」SHALL navigate to a full-screen album picker with glass-styled chrome (top bar with cancel/complete, grid thumbnails). The complete action MUST use `ColorScheme.primary` capsule styling consistent with the compose publish button. For UCG compose flow, complete MUST return local media without blocking OSS upload on the picker page.

原生相册页须为玻璃全屏；UCG compose 路径点「完成」须返回本地媒体，不得在相册页阻塞 OSS 上传。

#### Scenario: compose 路径完成返回本地媒体
- **WHEN** 用户在 UCG 发布相册页选中媒体并点击「完成」
- **THEN** App SHALL pop 本地媒体列表（`deferUpload`）
- **AND** App SHALL NOT 在相册页展示 OSS 上传 loading
- **AND** App SHALL 进入 compose 并以本地缩略图预填

#### Scenario: 相册页取消
- **WHEN** 用户点击相册页「取消」
- **THEN** App SHALL 返回入口前状态且不进入 compose

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

When no local draft exists, short-tap「+」SHALL present a glass-styled bottom sheet with at least「拍摄」and「从手机相册选择」. Camera capture MUST return local media to compose and MUST start background upload from compose. Gallery on native MUST use album picker with `deferUpload: true`. Mutual exclusion MUST be enforced in the album picker before compose opens.

入口 sheet 拍摄/相册须返回本地媒体进 compose，由 compose 后台上传；原生相册须 deferUpload。

#### Scenario: 拍摄照片本地进 compose
- **WHEN** 用户在 glass sheet 选择「拍摄」并拍摄照片
- **THEN** App SHALL 以本地路径进入 compose 并展示缩略图
- **AND** App SHALL 在 compose 内启动后台上传

#### Scenario: 拍摄视频本地进 compose
- **WHEN** 用户选择「拍摄」并录制视频
- **THEN** App SHALL 校验时长与大小后以本地路径进入 compose
- **AND** App SHALL 在 compose 内启动后台上传

#### Scenario: 相册进入自建页 deferUpload
- **WHEN** 用户选择「从手机相册选择」（原生）
- **THEN** App SHALL push 自建相册页且 `deferUpload` 为 true
- **AND** 完成后 SHALL 本地预填 compose

#### Scenario: Web 混选拒绝
- **WHEN** Web 降级 picker 返回同时含图片与视频
- **THEN** App SHALL 提示只能选一种类型
- **AND** App SHALL NOT 打开 compose
