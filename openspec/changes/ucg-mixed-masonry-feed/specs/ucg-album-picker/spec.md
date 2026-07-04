## MODIFIED Requirements

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

This requirement applies when media entry is triggered **from compose page controls**, not from Dock short-tap. Dock「+」MUST bypass this sheet per `ucg-compose-post`.

相册/拍摄入口 sheet MUST NOT 阻塞 Dock 直达 compose。

#### Scenario: Dock 不触发入口 sheet

- **WHEN** 用户从 Shell Dock 短按「+」
- **THEN** App MUST NOT 调用 `showUcgComposeEntrySheet` 作为第一步

#### Scenario: compose 内仍可相册选图

- **WHEN** 用户已在 compose 页点击添加图片
- **THEN** App MAY 打开相册 picker（`deferUpload: true`）或拍摄流程
