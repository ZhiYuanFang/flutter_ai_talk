## MODIFIED Requirements

### Requirement: Hub shows group QR when URL present
The client SHALL parse top-level `inviteGroupQrUrl` from the feature catalog response. The feature unlock hub (`/features/unlock`) MUST NOT show a page-level WeChat group QR block. When the URL is non-empty, the「如何获取邀请码」screen MUST show the WeChat group acquisition method with the QR image (centered caption above the image as product copy allows). When the URL is empty or absent, that WeChat method MUST NOT be shown. When the QR image fails to load, the client MUST hide the entire WeChat QR block including its caption. 有非空 `inviteGroupQrUrl` 时仅在「如何获取邀请码」页展示微信群二维码；开通中心页 MUST NOT 再展示页级群 QR；URL 空或不展示；图片加载失败时整块（含文案）隐藏。

#### Scenario: URL present shows on how-to page not hub
- **WHEN** catalog includes a non-empty `inviteGroupQrUrl`
- **THEN** the unlock hub MUST NOT render the former page-level group-QR block
- **AND** the invite how-to page MUST display the QR image loaded from that URL

#### Scenario: URL absent
- **WHEN** `inviteGroupQrUrl` is missing or empty
- **THEN** neither the hub nor the how-to page shows a WeChat group QR block

#### Scenario: Image load failure
- **WHEN** `inviteGroupQrUrl` is non-empty but the image fails to load on the how-to page
- **THEN** the client MUST NOT show the WeChat QR caption or an empty QR panel

### Requirement: Tap QR opens zoomable fullscreen preview
The client SHALL allow the user to tap the QR image on the「如何获取邀请码」screen to open a fullscreen zoomable preview of the same URL. The client MUST reuse the existing photo lightbox (`showUcgPhotoLightbox`) rather than a one-off dialog. The caption text MUST NOT open the preview when tapped. The client MUST NOT require a separate「点击放大」hint label. 点击如何获取页上的二维码图打开全屏可缩放预览（复用 lightbox）；仅图可点；不加副文案提示。

#### Scenario: Tap image opens lightbox
- **WHEN** the WeChat QR block is visible on the how-to page and the user taps the QR image
- **THEN** the client opens a fullscreen preview of that image that supports pinch-zoom

#### Scenario: Caption alone does not open preview
- **WHEN** the user taps only the WeChat group caption (not the image)
- **THEN** the client MUST NOT open the fullscreen preview
