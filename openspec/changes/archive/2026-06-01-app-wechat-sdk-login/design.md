## Context

胖宝 Flutter 应用已实现网关 `POST /device/app/api/login`（`wxCode` + `platform` → JWT），但 `wxCode` 来源仍为联调用 `WX_LOGIN_CODE`。微信开放平台要求移动应用使用微信客户端授权、网页使用 OAuth2 重定向；AppSecret 必须仅在后端保管。本设计在三端引入「取码 → 调既有 RemoteAuth」的统一路径。

## Goals / Non-Goals

**Goals:**

- Android / iOS 使用微信开放平台「移动应用」能力拉起微信并获取临时 `code`（即网关所称 `wxCode`）。
- Web 使用「网站应用」网页授权，在合法 `redirect_uri` 下获取 `code` 并交给同一登录链路。
- 登录失败、用户取消、未安装微信等场景有明确可观测行为（Toast / 对话框），不崩溃。
- 通过 `--dart-define` 或构建期配置注入 **AppId、Universal Link（iOS）、Android 包名签名相关已由开放平台登记**；仓库内不出现 AppSecret。

**Non-Goals:**

- 不修改网关登录契约与后端签发 JWT 的逻辑。
- 不在本变更内完成微信开放平台账号资质代填、审核或支付能力。
- 不强制替换为某一商业插件：设计以「推荐方案 + 可替换适配层」表述。

## Decisions

1. **适配层抽象**  
   - 引入 `WeChatAuthClient`（或等价命名）接口：`Future<String> obtainWxCode()`，按 `defaultTargetPlatform` / `kIsWeb` 分发实现。  
   - `RemoteAuthRepository` 接收可选的「取码委托」：优先 `obtainWxCode()`，失败或未实现时回退 `AppEnv.wxLoginCode`（仅开发）。  
   - **理由**：单测与 CI 可 mock 取码；生产与联调分支清晰。

2. **Android / iOS 插件选型**  
   - **推荐**：`fluwx`（社区成熟、同时覆盖 Android/iOS），版本与 Flutter SDK 对齐后锁定。  
   - **备选**：各端分别集成官方 SDK + MethodChannel，成本高、维护双栈。  
   - **理由**：降低双端样板代码；若团队禁用三方库可退回 MethodChannel。

3. **Web 授权流程**  
   - 使用微信 OAuth2：`https://open.weixin.qq.com/connect/oauth2/authorize`（或开放平台文档规定的网站应用入口），`redirect_uri` 指向本站路由（如 `/auth/wechat/callback`），由该页从 query 读取 `code` 后通过 `postMessage` 或内存状态（Riverpod + 路由参数）交给 `LoginScreen` 继续登录。  
   - **理由**：与微信网页规范一致；避免在 hash 路由中丢失 query（若使用 hash，需单独处理）。

4. **平台字段 `platform`**  
   - 与网关约定对齐：`web` / `ios` / `android`（若服务端后续改为 `android`，客户端一并调整）。  
   - **理由**：保持现有 `RemoteAuthRepository` 契约。

5. **安全**  
   - 仅 `appId`、部分回调 URL 进入客户端；**不得**提交 `AppSecret`。  
   - **理由**：符合开放平台与 OWASP 移动应用基线。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| Universal Link / 安卓包名签名配置错误导致无法回调 | 文档列出检查清单；在 `design` 关联任务中增加真机验证步骤 |
| Web 授权域名未备案或未加入开放平台白名单 | 在 README 明确前置条件；开发环境使用已登记测试号 |
| `fluwx` 与新版 Flutter/Gradle 不兼容 | 锁定版本；备选官方 SDK 方案 |
| 用户取消授权 | 捕获错误码，Toast「已取消」，不清理已有会话 |

## Migration Plan

1. 在微信开放平台完成移动应用 / 网站应用创建，配置签名、包名、Universal Link、授权回调域。  
2. 发版客户端：新用户走 SDK；老用户已存 JWT 的**不受影响**。  
3. 若需关闭旧联调路径：保留 `WX_LOGIN_CODE` 为可选，默认空即可。

## Open Questions

- 网站应用 `redirect_uri` 最终域名与路径（需与运维、网关 CORS/反向代理一致）。  
- 是否需要在登录页展示「微信用户协议」二次确认（除现有隐私政策外）。  
- iOS 是否已具备可用的 Universal Link 域名与 `apple-app-site-association` 托管。
