## ADDED Requirements

### Requirement: App Privacy 申报 MUST 与代码及政策一致

App Store Connect App Privacy questionnaire answers MUST align with `privacy-policy.html` and actual data flows documented in this change.

ASC App Privacy 问卷 MUST 按下列对照申报；与政策或代码不符时 MUST 先更新政策再申报。

#### Scenario: 联系信息 — 用户 ID

- **WHEN** 填写「Contact Info」类数据
- **THEN** MUST 申报收集用户 ID（微信 OpenID、Apple sub、社区昵称等标识）
- **AND** 用途 MUST 包含 App Functionality

#### Scenario: 用户内容 — UGC 与私信

- **WHEN** 填写「User Content」类数据
- **THEN** MUST 申报帖子、评论、图片/视频、私信内容
- **AND** 用途 MUST 包含 App Functionality
- **AND** MUST NOT 申报用于 Tracking（无 IDFA）

#### Scenario: 照片或视频 — UGC 媒体

- **WHEN** 填写「Photos or Videos」
- **THEN** MUST 申报用户上传的社区图片/视频
- **AND** 链接至 OSS/CDN 存储披露

#### Scenario: 不申报项 — 精确定位与通讯录

- **WHEN** 问卷询问 Location（Precise）或 Contacts
- **THEN** MUST 选择不收集（应用无 GPS、无通讯录权限）

#### Scenario: 不申报项 — 追踪

- **WHEN** 问卷询问「Data Used to Track You」
- **THEN** MUST 选择否（当前无 IDFA、无第三方广告/追踪 SDK）

#### Scenario: 第三方 AI 数据处理

- **WHEN** 问卷询问数据是否共享给第三方
- **THEN** MUST 披露 AI 润笔与内容审核场景下数据发送至第三方 AI/ moderation 服务（政策中具名为 DashScope、Green）
- **AND** 用途 MUST 为 App Functionality / 内容安全

#### Scenario: 音频 — 仅喂养语音

- **WHEN** 填写「Audio Data」
- **THEN** MUST 说明麦克风用于喂养记录语音转文字，非持久化原始音频
- **AND** MUST NOT 将 UGC 模块声明为收集音频（社区无麦克风）
