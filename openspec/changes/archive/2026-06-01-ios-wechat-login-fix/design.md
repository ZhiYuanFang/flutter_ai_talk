## Context

当前 iOS 微信登录链路由 `LoginScreen` → `AuthRepository.signInWithWeChat()` → `fluwx` 取码组成，但在构建参数注入、iOS 平台能力配置（Universal Link/Associated Domains）与运行时异常提示三处存在断点。一旦任一环节缺失，用户可能只看到按钮点击后无明显反馈，造成“无反应”体验。

## Goals / Non-Goals

**Goals：**

- 让 iOS 微信登录在“构建可用 + 运行可用 + 错误可感知”三个层面形成闭环。
- 确保 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 在 iOS 打包产物中可被运行时正确读取。
- 当微信 SDK 注册失败、无法拉起微信、回调配置缺失或平台异常时，登录页必须给出明确提示。
- 形成可执行的 iOS 发布前检查项，避免再次发布“按钮可点但不可登录”的版本。

**Non-Goals：**

- 不改动网关登录契约（`POST /device/app/api/login`）与 token 持久化语义。
- 不改造 Android/Web 微信登录行为，仅允许复用通用异常处理优化。
- 不在本次变更中引入新的第三方登录渠道。

## Decisions

1. **构建参数显式注入（iOS）**
   - 在 iOS 构建命令中显式传入 `--dart-define=WECHAT_APP_ID` 与 `--dart-define=WECHAT_UNIVERSAL_LINK`。
   - 继续保留 `prepare_ios_project.sh` 对 `pubspec.yaml` 的注入，用于插件侧与运行时侧双重一致。
   - **理由**：`String.fromEnvironment` 仅在编译期生效，仅写入环境变量不足以进入 Dart 常量。

2. **登录点击全链路异常兜底**
   - `LoginScreen._onWeChatLogin()` 增加最终兜底 `catch`，统一输出用户可理解错误文案。
   - `RemoteAuthRepository.signInWithWeChat()` 对微信取码层异常保持业务化转换，避免未捕获平台异常穿透 UI。
   - **理由**：满足“不可用必须可解释”，减少“无反应”主观感知。

3. **iOS 平台能力前置校验**
   - 发布流程新增检查：Associated Domains、`apple-app-site-association`、微信开放平台 Universal Link 配置必须一致。
   - 在 CI 中对关键配置缺失执行 fail-fast（按发布模式开关可配置），阻断不可登录包发布。
   - **理由**：该类问题多为配置型故障，后置排障成本高。

4. **可观测性与排障信息标准化**
   - 将“SDK 注册失败/未安装微信/拉起失败/授权超时/回调异常”等错误映射为稳定提示文案。
   - 在文档中维护“现象→检查项→修复动作”映射，缩短定位时间。
   - **理由**：降低线上人工排查成本，便于客服与测试协同。

## Risks / Trade-offs

- **风险：严格校验可能导致 CI 构建失败增多**
  - 缓解：仅在 iOS 发布模式强制；开发模式可降级为 warning。
- **风险：新增兜底提示可能掩盖底层具体异常**
  - 缓解：用户侧显示友好信息，日志侧保留原始异常。
- **风险：不同 iOS 版本/微信版本行为差异**
  - 缓解：补充真机冒烟矩阵（至少 2 台设备、2 个 iOS 大版本）。

## Migration Plan

1. 先落地 CI 与运行时最小修复（参数注入 + 异常兜底）。
2. 再补文档与发布检查清单，并在下一个 iOS 包执行完整冒烟。
3. 观察一周登录失败反馈；若仍异常，再追加更细粒度日志/埋点。

## Open Questions

- CI 对缺失微信配置应“强制失败”还是“允许构建但标红告警”？
- 是否需要在登录页增加临时诊断文案（仅 debug/profile 可见）以便现场排障？
- 是否将 iOS 微信登录冒烟纳入发布 gate（未通过不得发版）？