## 1. [flutter_ai_talk] iOS 权限脚本与工作流

> 能力：`ios-microphone-usage-string`、`ios-photo-camera-usage-strings`

- [x] 1.1 修改 `app/tool/ci/prepare_ios_project.sh`：`IOS_MICROPHONE_USAGE_DESCRIPTION`、`IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` 先 `.strip()`，空值回退内置默认文案
- [x] 1.2 同上脚本：新增 `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription` 写入；环境变量 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION`，空值回退 UGC 发帖场景默认文案
- [x] 1.3 修改 `.github/workflows/ios-build-core.yml`：在 `env` 与 secrets 声明中新增 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION`（optional）
- [x] 1.4 同步子工作流 `build-ios-appstore.yml`、`build-ios-testflight.yml`、`build-ios-adhoc.yml` 若需显式传递新 env（与 core 保持一致）
- [x] 1.5 本地或 CI 验证：构建后检查 `ios/Runner/Info.plist` 四个键均非空（脚本末尾已加非空校验；本地无 `ios/` 工程，待 CI 构建确认）

## 2. [flutter_ai_talk] iOS 文档与 GitHub Secrets

> 能力：`ios-microphone-usage-string`、`app-store-metadata-checklist`

- [x] 2.1 修正 `docs/ios-github-actions-checklist.md` §10 麦克风示例：替换笼统「需要麦克风权限以支持语音输入与录音」为与脚本默认一致的完整句式，并加注不得使用笼统描述
- [x] 2.2 同上文档：新增 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION` 可选 Secret 说明与示例
- [ ] 2.3 **运维（手动）**：检查 GitHub `IOS_MICROPHONE_USAGE_DESCRIPTION`——若为空字符串则删除该 Secret 或填入合规文案；同理检查 `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION`
- [ ] 2.4 **运维（手动，可选）**：配置相册/相机 Secret 覆盖默认文案

## 3. [flutter_ai_talk] UGC AI 润笔同意门控

> 能力：`ucg-ai-polish-consent`

- [x] 3.1 新建 `app/lib/config/ucg_ai_polish_consent_store.dart`：`UcgAiPolishConsentStore`，key `ucg_ai_polish_consent_v1`，API 镜像 `AiChatDataConsentStore`（`load` / `saveAccepted`）
- [x] 3.2 修改 `app/lib/ucg/ui/ucg_compose_screen.dart`：新增 `_ensureUcgAiPolishConsent()`，在 `_polishWithAi()` 开头调用；未同意时 `showGlassConfirmDialog`，标题「使用 AI 润笔前请知悉」，正文「您所选图片及当前正文将发送至第三方 AI 服务，用于生成润色文案。」，确认「同意并继续」；无链接、无勾选框
- [ ] 3.3 **手工验证（手动）**：首次润笔弹窗 → 同意后不再弹 → 拒绝则不请求 API → 与喂养 AI 同意互不影响

## 4. [go_ai_talk] 隐私政策 HTML

> 能力：`app-legal-docs`  
> 路径：`d:\work\go_ai_talk\resource\public\privacy-policy.html`  
> 先例：`openspec/changes/update-legal-docs-apple-sign-in`

- [x] 4.1 §1 增补 UGC 收集项：社区资料、帖子/评论/点赞/关注、私信、通知、媒体 OSS/CDN、hash 去重、IP→属地（非原始 IP）
- [x] 4.2 新增或扩展章节：第三方 AI 与审核——DashScope 润笔（图片+正文出站）、Green 内容审核；喂养 AI 对话为独立场景
- [x] 4.3 新增「我们不收集」矩阵：GPS、通讯录、UGC 麦克风、IDFA/追踪 SDK、Apple 邮箱姓名、服务端发帖草稿（仅设备本地草稿）
- [x] 4.4 增补利害关系/第三方服务说明（与 DashScope、Green 供应商关系）
- [x] 4.5 更新生效日期；确认 `/privacy-policy.html` 路由无需改动（`internal/controller/gateway_app_register.go` 已绑定静态文件，无需修改）

## 5. [go_ai_talk] 用户协议 HTML

> 能力：`app-legal-docs`  
> 路径：`d:\work\go_ai_talk\resource\public\user-agreement.html`

- [x] 5.1 增补 UGC 社区行为规范：发帖/评论/互动准则，禁止违法侵权骚扰 spam 等，违规处理
- [x] 5.2 更新生效日期

## 6. [go_ai_talk] 部署

- [ ] 6.1 **部署（手动）**：合并 go_ai_talk PR 并部署 gateway-app，使线上 `/privacy-policy.html`、`/user-agreement.html` 返回新内容
- [ ] 6.2 **抽检（手动）**：浏览器与 App WebView 抽检两个 URL 可访问且内容已更新

## 7. [ASC 人工] App Store Connect 提审准备

> 能力：`app-store-metadata-checklist`、`app-store-connect-privacy-labels`

- [ ] 7.1 **截图（Guideline 2.3.10）**：重拍全部 iPhone 截图，确保含原生 iOS 状态栏；覆盖 ASC 要求的各尺寸
- [ ] 7.2 **App Privacy 问卷**：按 `app-store-connect-privacy-labels` spec 申报——用户 ID、用户内容、照片/视频、音频（仅喂养语音）；不申报精确定位、通讯录、追踪
- [ ] 7.3 确认隐私政策 URL 指向已部署的 `https://<domain>/privacy-policy.html`
- [ ] 7.4 触发 flutter_ai_talk iOS CI 构建 v1.0.2 `.ipa`，验证 plist 权限字符串非空
- [ ] 7.5 在 ASC 选择新 build，填写审核备注（说明已修复麦克风描述、更新隐私政策、新增 AI 润笔告知）
- [ ] 7.6 Submit for Review

## 8. 收尾

- [ ] 8.1 **PR（手动）**：flutter_ai_talk PR 描述引用本 change 与各 capability 需求标题
- [ ] 8.2 **PR（手动）**：go_ai_talk PR 描述链接 `flutter_ai_talk/openspec/changes/ucg-app-store-privacy-compliance`
- [ ] 8.3 **归档前（手动）**：确认 Open Question「账号注销 UGC 级联」是否需跟进单独 change（政策 §7 已用保守表述，待产品/后端确认后修订）
