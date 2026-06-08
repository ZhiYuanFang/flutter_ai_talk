## MODIFIED Requirements

### Requirement: 隐私政策 SHALL 披露 UGC 社区与第三方 AI 数据处理

`resource/public/privacy-policy.html` MUST document UGC community data collection, third-party AI processing (DashScope polish, Green moderation), related-party disclosure, and a collect vs not-collect matrix aligned with actual app behavior.

`resource/public/privacy-policy.html` MUST 增补：UGC 社区模块收集的资料与内容；AI 润笔与内容审核涉及的第三方服务（具名 DashScope、Green）；利害关系说明；「我们收集 / 我们不收集」对照表。文档 MUST 更新生效日期。

#### Scenario: 用户阅读 UGC 数据收集说明

- **WHEN** 用户打开 `/privacy-policy.html`
- **THEN** 页面 MUST 说明收集 UGC 个人资料（昵称、头像等）、帖子/评论/点赞/关注、私信、互动通知
- **AND** MUST 说明媒体文件存储于 OSS/CDN 及内容 hash 去重机制
- **AND** MUST 说明 IP 仅解析为属地标签，不持久化原始 IP

#### Scenario: 用户阅读第三方 AI 披露

- **WHEN** 用户阅读隐私政策第三方服务章节
- **THEN** MUST 披露 AI 润笔将所选图片与正文发送至 DashScope 生成文案
- **AND** MUST 披露 Green 内容安全用于文本/图片审核
- **AND** MUST 说明喂养 AI 对话为独立场景（输入与近期喂养记录）

#### Scenario: 用户阅读不收集声明

- **WHEN** 用户阅读「我们不收集」或等效章节
- **THEN** MUST 明确不收集 GPS 精确定位、通讯录、IDFA/第三方追踪、Apple 邮箱姓名
- **AND** MUST 说明 UGC 模块不使用麦克风
- **AND** MUST 说明发帖草稿仅保存在用户设备本地

### Requirement: 用户协议 SHALL 包含 UGC 社区行为规范

`resource/public/user-agreement.html` MUST include community conduct rules for the UGC module. Document MUST include an updated effective date.

`resource/public/user-agreement.html` MUST 增补 UGC 社区行为规范（禁止违法、侵权、骚扰、 spam 等）；MUST 更新生效日期。

#### Scenario: 用户阅读社区规范

- **WHEN** 用户打开 `/user-agreement.html`
- **THEN** 页面 MUST 包含社区发帖、评论、互动的行为准则与违规处理说明

### Requirement: 合规文档 URL SHALL 保持不变

gateway-app exposed legal document paths MUST remain `/privacy-policy.html` and `/user-agreement.html`; clients MUST NOT need URL changes for this revision.

gateway-app 暴露路径 MUST 仍为 `/privacy-policy.html` 与 `/user-agreement.html`（`gateway_app_register.go`）；客户端 WebView 加载 URL MUST NOT 变更。

#### Scenario: 客户端加载合规文档

- **WHEN** 客户端请求既有隐私政策或用户协议 URL
- **THEN** gateway MUST 返回更新后的 HTML 内容
- **AND** 路径 MUST 与修订前相同
