# iOS 微信登录修复任务

## 1. 构建参数与发布门禁

- [x] 1.1 在 iOS 构建流程中为 `flutter build ipa` 显式注入 `WECHAT_APP_ID` 与 `WECHAT_UNIVERSAL_LINK` 的 `--dart-define` 参数。
- [x] 1.2 保持 `prepare_ios_project.sh` 与运行时参数来源一致，避免仅插件侧生效、Dart 侧失效。
- [x] 1.3 在发布模式下增加 fail-fast 校验：缺失微信关键参数时阻断产包并输出修复提示。

## 2. iOS 微信登录运行时可靠性

- [x] 2.1 在 `LoginScreen` 微信登录入口补充最终兜底异常处理，确保异常必有可见提示且加载态可恢复。
- [x] 2.2 审核并收敛 `RemoteAuthRepository` 与微信客户端异常映射，统一为可读业务错误。
- [x] 2.3 校验 `fluwx` iOS 注册与授权失败路径文案，覆盖注册失败、无法拉起、授权超时、用户取消等场景。

## 3. iOS 配置一致性校验

- [x] 3.1 在 CI 或发布检查清单中新增 Associated Domains 与 Universal Link 一致性检查项。
- [x] 3.2 明确 `apple-app-site-association` 与微信开放平台配置对应关系，并在文档中提供最小排障步骤。
- [x] 3.3 对配置不一致场景给出阻断级结论或高优先级告警策略（按发布模式定义）。

## 4. 验证与文档收口

- [x] 4.1 更新 `app/README.md` 与 iOS 发布文档，补充 iOS 微信登录必填参数与检查顺序。
- [ ] 4.2 完成 iOS 真机冒烟：微信登录成功、取消授权、未安装微信/配置错误提示三类场景。
- [x] 4.3 执行 OpenSpec 校验并确认 `ios-wechat-login-fix` 变更达到 apply-ready。
