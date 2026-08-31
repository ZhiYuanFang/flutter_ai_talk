## ADDED Requirements

### Requirement: Photo lightbox long-press SHALL offer save to device album on native

On iOS and Android, when the user **long-presses** the current image in a fullscreen photo lightbox opened via `showUcgPhotoLightbox`, `showUcgLocalImageLightbox`, or equivalent pinch-zoom full-image viewer, the client MUST offer saving that image to the device photo library (after an explicit confirm step such as a dialog, unless product later opts out). On success the client MUST show user-visible success feedback; on failure MUST show user-visible failure feedback. The client MUST request album **write/add** permission as required by the platform before saving; if permission is denied, the client MUST NOT pretend success and MAY offer opening app settings. Saving MUST target the image bytes (network full URL / local file / in-memory bytes), not a screenshot of the zoomed viewport.

在 iOS/Android 全屏图片 lightbox 中长按当前图时，客户端 **必须** 在确认后尝试保存到系统相册；成功/失败 **必须** 有可见反馈；写权限拒绝时 **必须 NOT** 伪造成功。保存 **必须** 基于图像字节而非缩放视口截图。

#### Scenario: 网络大图长按保存成功

- **WHEN** 用户在原生端 lightbox 查看远程图并长按且确认保存且权限已授予且下载/解码成功
- **THEN** 客户端 MUST 将图片写入系统相册
- **AND** MUST 展示成功反馈

#### Scenario: 拒绝写权限

- **WHEN** 用户确认保存但相册写权限被拒绝
- **THEN** 客户端 MUST NOT 写入相册
- **AND** MUST 展示失败或需授权的可见提示（MAY 引导设置）

#### Scenario: 本地图长按可保存

- **WHEN** 用户在原生端本地图片 lightbox（bytes 或可读 filePath）长按并确认保存且权限已授予
- **THEN** 客户端 MUST 将对应图像写入系统相册

### Requirement: Web lightbox save-to-album SHALL be unavailable with visible feedback

On Web, long-press save-to-system-album MUST NOT silently fail. The client MUST show user-visible feedback that saving to the device album is unsupported on Web (optional: offer browser download instead, if implemented).

Web 上长按保存系统相册 **必须 NOT** 静默失败；**必须** 给出不支持（或下载替代）的可见反馈。

#### Scenario: Web 长按有提示

- **WHEN** 用户在 Web lightbox 长按意图保存
- **THEN** 客户端 MUST 展示不支持系统相册（或提供下载）的可见反馈
- **AND** MUST NOT 静默无响应

### Requirement: Lightbox save MUST NOT break existing dismiss and zoom gestures

Adding long-press save MUST preserve existing lightbox behaviors: vertical dismiss, tap-to-dismiss (if any), and pinch-zoom via `InteractiveViewer` (or equivalent). Long-press MUST NOT be required to open the lightbox.

增加长按保存 **必须** 保留下拉关闭与 pinch-zoom 等既有手势；打开 lightbox **不得** 依赖长按。

#### Scenario: 仍可 pinch 与关闭

- **WHEN** 用户在已支持长按保存的 lightbox 中双指缩放或按既有方式关闭
- **THEN** 缩放与关闭行为 MUST 仍可用
