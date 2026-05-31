## Why

当前 iOS 端点击「微信登录」在部分构建与环境中表现为无响应或无明确错误提示，导致用户无法完成登录并直接影响首要转化路径。该问题已在现网反馈出现，需尽快修复并建立可验证的配置与运行时兜底，降低回归风险。

## What Changes

- 修复 iOS 微信登录关键配置链路，确保 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 在 iOS 构建与运行时可被一致消费。
- 增加 iOS 微信登录前置配置校验与失败提示：当 AppId、Universal Link、Associated Domains 或授权回调不可用时，必须给出可理解错误，而非静默失败。
- 优化登录页微信点击后的异常兜底与状态反馈，避免用户感知“点了没反应”。
- 补齐 CI/构建文档与发布检查清单，明确 iOS 微信登录可用性的必检项与排障路径。
- **BREAKING**：iOS 构建流程将对微信相关必填配置执行更严格校验；缺失配置的构建可能被阻断以防止发布不可登录包。

## Capabilities

### New Capabilities
- `ios-wechat-login-reliability`: 约束 iOS 微信登录在构建、运行时、错误提示与可观测性上的可靠性行为。

### Modified Capabilities
- （无）

## Impact

- 受影响代码：`app/lib/ui/login_screen.dart`、`app/lib/wechat/wechat_impl_mobile.dart`、`app/lib/config/env.dart`、相关 provider 与错误提示链路。
- 受影响构建：`.github/workflows/build-ios-ipa.yml`、`app/tool/ci/prepare_ios_project.sh`、`app/tool/ci/configure_ios_project.rb`（或等价 iOS 配置脚本）。
- 受影响文档：`app/README.md`、`docs/github-ios-ipa.md`、`docs/ios-github-actions-checklist.md`。
- 外部系统：Apple Associated Domains 与 `apple-app-site-association`、微信开放平台 iOS 配置一致性要求。