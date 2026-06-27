## MODIFIED Requirements

### Requirement: 隐私政策 SHALL 披露 UGC 社区与第三方 AI 数据处理

`resource/public/privacy-policy.html` MUST document UGC community data collection, third-party AI processing (DashScope polish, Green moderation), related-party disclosure, and a collect vs not-collect matrix aligned with actual app behavior.

`resource/public/privacy-policy.html` MUST 增补：UGC 社区模块收集的资料与内容；AI 润笔与内容审核涉及的第三方服务（具名 DashScope、Green）；利害关系说明；「我们收集 / 我们不收集」对照表。文档 MUST 更新生效日期。When-In-Use precise location for UCG distance display MUST be documented as optionally collected with user consent; denial MUST NOT block core app use.

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

#### Scenario: 用户阅读定位收集说明

- **WHEN** 用户阅读「我们收集」或 UGC 定位相关章节
- **THEN** MUST 说明在用户授权「使用时定位」后，App 会读取设备坐标用于 UCG 广场展示动态距离及发帖附带位置
- **AND** MUST 说明拒绝定位仍可使用 UGC，仅不展示距离

#### Scenario: 用户阅读不收集声明

- **WHEN** 用户阅读「我们不收集」或等效章节
- **THEN** MUST 明确不收集通讯录、IDFA/第三方追踪、Apple 邮箱姓名
- **AND** MUST NOT 声明「不收集 GPS 精确定位」（已改为可选使用时收集）
- **AND** MUST 说明 UGC 模块不使用麦克风
- **AND** MUST 说明发帖草稿仅保存在用户设备本地
