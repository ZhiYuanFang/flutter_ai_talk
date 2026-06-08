## Context

### 审核拒信（v1.0.1）

| Guideline | 问题 | 处置方式 |
|-----------|------|----------|
| **2.3.10** | 截图未展示原生 iOS 状态栏 | App Store Connect 重拍/替换截图（人工） |
| **5.1.1(ii)** | `NSMicrophoneUsageDescription` 缺失或为空 | 修复 CI 注入 + GitHub Secret + 文档示例 |

### 当前代码状态

**iOS 权限脚本**（`app/tool/ci/prepare_ios_project.sh`）：

- `NSMicrophoneUsageDescription` 已有合规默认文案（含育儿语音示例），但 `os.getenv('IOS_MICROPHONE_USAGE_DESCRIPTION', default)` **不会**在 Secret 为空字符串时回退——GitHub Actions 传入 `secrets.IOS_MICROPHONE_USAGE_DESCRIPTION` 若存在但为空，会覆盖默认值为 `""`。
- `NSSpeechRecognitionUsageDescription` 同理。
- **尚未写入** `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`；UGC 发帖通过 `image_picker` / 相册选择器触发，提审前必须补齐。

**合规文档**（go_ai_talk）：

- `privacy-policy.html` 生效日期 2026-06-06，含 Apple 登录说明，**缺少** UGC 社区、AI 润笔、内容审核、第三方服务披露。
- `user-agreement.html` **缺少** 社区行为规范。
- 由 `gateway_app_register.go` 静态托管，URL 不变。

**客户端同意门控**：

- `AiChatDataConsentStore`（`ai_chat_data_consent_v1`）已在 `home_screen.dart` 门控喂养 AI 对话，弹窗使用 `showGlassConfirmDialog`。
- `ucg_compose_screen.dart` 的 `_polishWithAi()` **无**同意门控，直接调用 `ucgRepository.polishPost(imageKeys, text)`。

### 数据收集边界（代码落地）

**收集**：

| 类别 | 说明 |
|------|------|
| 账户标识 | 微信 OpenID/头像/昵称；Apple `sub`（匿名标识符） |
| UGC 资料 | 社区昵称、头像、简介 |
| UGC 内容 | 帖子、评论、点赞、关注关系 |
| 私信 | Redis 存储，服务端持久化 |
| 通知 | 互动通知记录 |
| 媒体 | OSS 上传 + CDN 分发；内容 hash 去重 |
| 属地 | IP 解析为属地标签，**不**持久化原始 IP |
| 发帖草稿 | **仅设备本地**（`ucgComposeDraftStoreProvider`） |
| AI 润笔出站 | 所选图片 key + 正文文本 → 第三方 AI（DashScope） |
| 内容审核 | 文本/图片 → Green  moderation |
| 喂养数据 | 既有育儿记录（AI 对话同意已覆盖） |

**不收集**：

| 类别 | 说明 |
|------|------|
| GPS 精确定位 | 无位置权限请求 |
| 通讯录 | 无访问 |
| UGC 麦克风 | 社区模块无语音录制 |
| IDFA / 第三方分析 SDK | 无集成 |
| Apple 邮箱/姓名 | 后端仅 `apple_sub` |
| 服务端发帖草稿 | 客户端 `submit: true` 直发，无服务端 draft API |

### 锁定产品决策

1. **AI 润笔同意与喂养 AI 同意分离**——独立 key、独立弹窗，互不复用。
2. **政策 HTML 具名第三方**（DashScope、Green）；**润笔弹窗仅用「第三方 AI」**，不提供政策链接。
3. **无勾选框**——与 `ai-chat-data-consent` 一致，单次确认即持久化。
4. **设备本地持久化**——`SharedPreferences`，不上报服务端。

## Goals / Non-Goals

**Goals:**

- 消除 Guideline 5.1.1(ii) 根因，确保 `.ipa` 内四类权限字符串非空且语义合规。
- 更新 go_ai_talk 法律文档，使 UGC + 第三方 AI 披露与代码行为一致。
- 为 AI 润笔增加首次使用前同意门控，满足 App Store 数据使用透明性预期。
- 提供 ASC 人工步骤清单（截图、隐私标签），支撑 v1.0.2 提审。

**Non-Goals:**

- 账号注销时 UGC 数据级联删除策略（见 Open Questions）。
- 在润笔弹窗内嵌入 WebView 政策链接。
- 修改喂养 AI 对话现有同意流程。
- 实现 App Store Connect API 自动化隐私标签填写。
- Android 权限文案变更（本次聚焦 iOS 拒审项）。

## Decisions

### D1：空 Secret 回退——脚本层 `.strip()` 判空

**选择**：在 `prepare_ios_project.sh` 的 Python 块中，对每个 `IOS_*_USAGE_DESCRIPTION` 环境变量先 `.strip()`，若为空则使用内置默认文案。

**理由**：GitHub Secret 一旦创建即存在键，值为 `""` 时 `os.getenv` 仍返回空串。脚本层判空比要求运维「删除 Secret」更稳健。

**备选**：工作流层 `${{ secrets.X || 'default' }}`—— rejected：默认值过长不宜内联 YAML，且与脚本单一来源冲突。

### D2：相册/相机默认文案——UGC 发帖场景

**选择**：

- `NSPhotoLibraryUsageDescription`：说明用于 UGC 发帖时从相册选择图片/视频。
- `NSCameraUsageDescription`：说明用于 UCG 发帖时拍摄照片/视频。

**环境变量**：`IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION`。

### D3：AI 润笔同意——镜像 `AiChatDataConsentStore` 模式

**选择**：

- 新建 `UcgAiPolishConsentStore`，key `ucg_ai_polish_consent_v1`。
- `_polishWithAi()` 开头调用 `_ensureUcgAiPolishConsent()`，未同意则 `showGlassConfirmDialog` 拦截。
- 文案锁定（见 proposal），确认按钮「同意并继续」。

**理由**：与现有 `home_screen.dart` 模式一致，改动面最小，审核员可理解。

### D4：法律文档在 go_ai_talk 维护，OpenSpec 变更在 flutter_ai_talk

**选择**：本变更的 `tasks.md` 用 `[go_ai_talk]` 前缀标注跨仓库任务；`app-legal-docs` delta spec 描述 go_ai_talk 文件行为。

**理由**：gateway 与 HTML 源码在 go_ai_talk；flutter 变更作为统筹提审的单点 OpenSpec 入口。先例：`update-legal-docs-apple-sign-in`。

### D5：App Privacy 标签——文档对照表，非代码

**选择**：`app-store-connect-privacy-labels` spec 列出 ASC 须申报的数据类型及与政策/HTML 的对应关系；实现为 `tasks.md` 人工勾选项。

**理由**：Apple 无稳定 API 写入隐私标签；申报在 ASC 网页完成。

### D6：麦克风 checklist 示例——替换笼统文案

**选择**：`docs/ios-github-actions-checklist.md` §10 示例改为与脚本默认一致的完整句式，并加注「不得使用笼统描述」。

**理由**：现有示例「需要麦克风权限以支持语音输入与录音」违反 `ios-microphone-usage-string` 基线，易误导填写 GitHub Secret。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| GitHub Secret 仍保留空值，但脚本已判空 | 任务中明确要求删除或更新 Secret；CI 日志打印最终写入的 plist 键（不含敏感值） |
| 政策 HTML 与 ASC 隐私标签手工填写不一致 | `app-store-connect-privacy-labels` 提供字段级对照；提审前双人核对 |
| AI 润笔同意与喂养同意分离，用户可能看到两次弹窗 | 产品已锁定；两次场景不同（社区发帖 vs 喂养对话） |
| UGC 账号注销级联未定义 | 记入 Open Questions；政策暂用「注销时删除或匿名化账户相关信息」通用表述 |
| 跨仓库任务遗漏执行 | tasks.md 分节 `[flutter_ai_talk]` / `[go_ai_talk]` / `[ASC 人工]` |

## Migration Plan

1. **go_ai_talk**：部署更新后的 HTML（gateway 静态文件，随 gateway-app 发布即可）。
2. **flutter_ai_talk**：合并脚本 + 客户端改动 → 触发 iOS CI 构建新 `.ipa`。
3. **GitHub Secrets**：更新或删除空的 `IOS_MICROPHONE_USAGE_DESCRIPTION`；按需新增相册/相机 Secret。
4. **ASC 人工**：重拍截图 → 更新 App Privacy → 选新 build → 提交审核。
5. **回滚**：HTML 可 git revert；客户端 consent store 新增 key 不影响旧用户；plist 脚本 revert 后重跑 CI。

## Open Questions

1. **账号注销 UGC 级联**：用户注销时帖子/评论/私信是否软删、硬删或匿名化？需产品/后端确认后再修订政策 §4 与实现。
2. **App Privacy「数据用于追踪」**：当前无 IDFA，应申报「否」；若未来加分析 SDK 须重审。
3. **Green / DashScope 供应商名称**：政策 HTML 是否写全称「阿里云 DashScope」「阿里云内容安全 Green」——建议写全称以便 ASC 对照。
4. **go_ai_talk OpenSpec 归档**：本变更 specs 在 flutter 仓库；go 侧是否需镜像 change 或仅 PR 引用本 tasks——建议 go PR 描述链接本 change。
