## MODIFIED Requirements

### Requirement: Compose video SHALL preview with first frame not file path

When the user selects a video for compose, the screen MUST show a visual preview (first frame or CDN poster for remote slots) with a play affordance. The app MUST NOT display the raw local file path or objectKey filename as the primary video label.

用户选视频后须展示首帧/封面预览与播放图标，不得用文件路径字符串作为主展示。

#### Scenario: 本地视频首帧预览
- **WHEN** 用户从相册或拍摄选入本地视频
- **THEN** compose 页 SHALL 在 1 秒内展示首帧缩略图（或 loading 占位）
- **AND** SHALL NOT 展示完整文件路径作为主文案

#### Scenario: 点击 compose 视频全屏
- **WHEN** 用户点击 compose 页视频预览区
- **THEN** App SHALL 打开全屏视频播放器
- **AND** 用户 MAY 播放/暂停与下滑关闭
