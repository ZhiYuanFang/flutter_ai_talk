## Why

胖宝 v1.0.1 在 Apple App Store 审核中被拒，涉及 Guideline 2.3.10（截图须含原生 iOS 状态栏）与 Guideline 5.1.1(ii)（`NSMicrophoneUsageDescription` 为空或过于笼统）。与此同时，UGC 社区、AI 润笔、相册/相机权限等新功能已在客户端上线，但 **go_ai_talk** 合规 HTML 与 **flutter_ai_talk** 客户端告知流程尚未同步，存在隐私政策与 App Privacy 申报不一致的风险。本次变更在跨仓库范围内一次性补齐 App Store 合规缺口，为 v1.0.2 重新提审做准备。

## What Changes

### Apple App Store / iOS 构建

- **Guideline 2.3.10**：在 App Store Connect 操作清单中明确「截图须使用含原生 iOS 状态栏的真机/模拟器素材」，属 ASC 人工步骤，非代码变更。
- **Guideline 5.1.1(ii)**：修复 `NSMicrophoneUsageDescription` 为空的问题——根因疑为 GitHub Secret 设为空字符串或 `docs/ios-github-actions-checklist.md` 中的笼统示例覆盖了 `prepare_ios_project.sh` 的合规默认文案。
- 增强 `app/tool/ci/prepare_ios_project.sh`：**空环境变量须回退至脚本默认文案**；新增 `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription` 写入及对应 GitHub Secrets 支持。
- 修正 `docs/ios-github-actions-checklist.md` 中麦克风权限示例，与 `ios-microphone-usage-string` 基线一致。
- 新增 App Store Connect 隐私标签与元数据核对清单（`app-store-metadata-checklist`）。

### go_ai_talk 合规文档

- 更新 `resource/public/privacy-policy.html`：UGC 社区数据收集、第三方 AI（DashScope 润笔、Green 内容审核）、利害关系说明、收集/不收集矩阵。
- 更新 `resource/public/user-agreement.html`：社区行为规范。
- 路径保持 `/privacy-policy.html`、`/user-agreement.html`（`gateway_app_register.go` 已注册，无需改路由）。

### flutter_ai_talk 客户端

- 新增 **AI 润笔独立同意门控**：`UcgAiPolishConsentStore`（key `ucg_ai_polish_consent_v1`），在 `ucg_compose_screen.dart` 的 `_polishWithAi` 前拦截。
- 弹窗文案锁定：标题「使用 AI 润笔前请知悉」，正文「您所选图片及当前正文将发送至第三方 AI 服务，用于生成润色文案。」；**不含**隐私政策链接、**不含**勾选框；设备本地持久化；与 `ai-chat-data-consent` 分离。

## Capabilities

### New Capabilities

- `ucg-ai-polish-consent`：UGC 发帖 AI 润笔首次使用前的一次性设备本地同意门控。
- `ios-photo-camera-usage-strings`：iOS 相册与相机权限用途说明（`NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`）的 CI 注入与默认文案。
- `app-store-metadata-checklist`：App Store Connect 截图、隐私标签、审核备注等人工核对清单。
- `app-store-connect-privacy-labels`：App Privacy 申报与代码/政策一致的字段级对照说明（ASC 人工填写，非代码）。

### Modified Capabilities

- `ios-microphone-usage-string`：空 `IOS_MICROPHONE_USAGE_DESCRIPTION` 须回退默认文案；补充 `NSSpeechRecognitionUsageDescription` 同等空值回退语义；文档示例不得引导笼统文案。
- `app-legal-docs`（**go_ai_talk** 仓库）：隐私政策与用户协议增补 UGC、第三方 AI、收集/不收集边界。

## Impact

| 范围 | 路径 / 系统 |
|------|-------------|
| **flutter_ai_talk** | `app/tool/ci/prepare_ios_project.sh`、`.github/workflows/ios-build-core.yml`、`docs/ios-github-actions-checklist.md`、`app/lib/config/ucg_ai_polish_consent_store.dart`（新建）、`app/lib/ucg/ui/ucg_compose_screen.dart` |
| **go_ai_talk** | `resource/public/privacy-policy.html`、`resource/public/user-agreement.html` |
| **人工 / ASC** | App Store Connect 截图重拍、App Privacy 标签填写、审核备注 |
| **GitHub Secrets** | `IOS_MICROPHONE_USAGE_DESCRIPTION`（删除空值或填合规文案）、`IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION`、`IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION` |
| **不受影响** | 喂养 AI 对话同意（`ai_chat_data_consent_v1`）、gateway 合规 URL、客户端 WebView 加载路径 |
