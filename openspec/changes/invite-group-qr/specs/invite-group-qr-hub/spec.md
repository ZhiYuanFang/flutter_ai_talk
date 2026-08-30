## ADDED Requirements

### Requirement: Hub shows group QR when URL present
The client SHALL parse top-level `inviteGroupQrUrl` from the feature catalog response. When the URL is non-empty, the feature unlock hub MUST show a page-level block with the centered caption「加入微信群获取邀请码」directly above the QR image. When the URL is empty or absent, the client MUST NOT show that block. When the QR image fails to load, the client MUST hide the entire block including the caption (MUST NOT leave an orphan caption). 有非空 `inviteGroupQrUrl` 时展示居中文案与二维码；URL 空则不展示；图片加载失败时整块（含文案）隐藏。

#### Scenario: URL present
- **WHEN** catalog includes a non-empty `inviteGroupQrUrl`
- **THEN** the hub displays the caption and the QR image loaded from that URL

#### Scenario: URL absent
- **WHEN** `inviteGroupQrUrl` is missing or empty
- **THEN** the hub does not render the group-QR block

#### Scenario: Image load failure
- **WHEN** `inviteGroupQrUrl` is non-empty but the image fails to load
- **THEN** the hub MUST NOT show the caption or an empty QR panel

### Requirement: Tap QR opens zoomable fullscreen preview
The client SHALL allow the user to tap the QR image to open a fullscreen zoomable preview of the same URL. The client MUST reuse the existing photo lightbox (`showUcgPhotoLightbox`) rather than a one-off dialog. The caption text MUST NOT open the preview when tapped. The client MUST NOT require a separate「点击放大」hint label. 点击二维码图打开全屏可缩放预览（复用 lightbox）；仅图可点；不加副文案提示。

#### Scenario: Tap image opens lightbox
- **WHEN** the group-QR block is visible and the user taps the QR image
- **THEN** the client opens a fullscreen preview of that image that supports pinch-zoom

#### Scenario: Caption alone does not open preview
- **WHEN** the user taps only the caption「加入微信群获取邀请码」
- **THEN** the client MUST NOT open the fullscreen preview
