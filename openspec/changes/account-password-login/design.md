## Context

当前 Flutter 客户端登录链路以微信授权为主，`AuthRepository` 与 `LoginScreen` 的产品语义均围绕 `signInWithWeChat()` 设计。后端已提供账号密码体系接口（主登录、注册、改密、绑定微信、绑定设备、微信账号补齐用户名密码），若客户端继续维持单登录入口，会导致联调断层与功能不可用。

本变更是跨 UI、仓储抽象、会话持久化与账号管理流程的横切改动：既要恢复账号密码建会话，又要保持微信登录和既有 token 刷新、`deviceNo` 缓存、设置页画像保存逻辑的兼容。

## Goals / Non-Goals

**Goals:**

- 在不破坏现有微信登录的前提下，新增账号密码登录并建立会话。
- 明确账号体系接口分层：匿名接口（登录/注册）与 Bearer 接口（改密/绑定）。
- 登录页提供双入口并统一输入校验、错误提示与成功跳转链路。
- 为后续设置页账号管理（改密、绑定微信、绑定设备、补齐用户名密码）提供稳定仓储能力。

**Non-Goals:**

- 本变更不重构历史/趋势/画像业务接口契约。
- 本变更不替换现有 token 刷新机制与 `SessionController` 存储模型。
- 本变更不引入第三方身份提供方（如 Apple/Google）登录。
- 本变更不定义后端密码策略以外的新安全规则（例如图形验证码、风控阈值）。

## Decisions

1. **账号密码主登录接口选择**  
   交互式建会话统一使用 `POST /device/app/api/username_login`，因为该接口直接返回 `accessToken`、`refreshToken`、`deviceNo` 等会话必要字段。`POST /device/app/api/user/username/login` 仅作为业务登录校验能力，不参与 token 建立。  
   - 备选：直接使用 `/user/username/login` 作为主登录。未采用原因：该接口不发 token，会造成客户端再次换票或额外建会话步骤。

2. **Auth 抽象扩展而非拆新仓储**  
   在 `AuthRepository` 增加账号体系方法（用户名密码登录、注册、改密、绑定微信、绑定设备、微信补齐用户名密码），由 `RemoteAuthRepository` 统一实现，继续复用现有 `_persistLoginData()` 与异常处理。  
   - 备选：新建 `AccountRepository`。未采用原因：短期会增加 provider 组合复杂度，且会话写入职责仍依赖 auth 层。

3. **登录页采用双入口单状态机**  
   在 `LoginScreen` 保留微信入口并新增账号密码表单，提交前对 `account` 做 `trim + lowercase`，并执行 `^[a-z0-9_]{4,32}$` 校验；`password` 校验 `6-64`。两条登录路径均进入同一 `loading -> success/navigate -> error toast` 生命周期。  
   - 备选：账号登录独立新页面。未采用原因：会增加路由切换与授权回流复杂度，不利于联调。

4. **登录渠道枚举增加 `username`**  
   `SignInChannel` 扩展 `username`，新登录成功后写入该值；历史 `device/wechat/unknown` 仍保持可读。设置页保存画像分支按“是否设备号登录”判断，`username` 与 `wechat` 统一走非设备分支，避免误调用 `user/save`。

5. **接口鉴权边界**  
   - 匿名：`/username_login`、`/user/username/register`、`/user/username/login`。
   - Bearer：`/user/username/bindwx`、`/user/username/bind_device`、`/user/username/change_password`、`/user/wx/create_username`。  
   通过既有 `ApiClient` 的 `withAuthorization` 参数与 `authorizedApiClientProvider` 实现边界，不新增网络层。

## Risks / Trade-offs

- **[风险] 双入口增加状态分支，可能引入重复提交或错误提示不一致** → **缓解**：统一入口状态机、统一异常映射、限制按钮在 `loading` 时禁用。
- **[风险] `username` 渠道引入后，画像保存分支行为可能与后端预期不一致** → **缓解**：在联调阶段确认 `user/save` 与 `auto_save` 适用范围，并记录到 README。
- **[风险] 后端两条用户名登录接口语义漂移** → **缓解**：在实现中显式区分“建会话接口”和“业务登录接口”，并在 spec 场景固定预期。
- **[风险] 账号规则大小写和 trim 处理前后不一致** → **缓解**：前端统一规范化后再提交，并在错误提示中给出明确规则。

## Migration Plan

1. 先落 OpenSpec（proposal/design/specs/tasks）并通过校验。
2. 代码阶段先扩展 `AuthRepository` 与 `RemoteAuthRepository`，保证接口能力完备。
3. 再改 `LoginScreen` 双入口 UI 与表单校验，接入新仓储方法。
4. 扩展 `SignInChannel` 与设置页分支兼容。
5. 更新 README 与联调文档，明确接口与测试路径。
6. 灰度验证：微信登录回归 + 账号密码新链路 + token 刷新 + 画像读写回归。

回滚策略：若发布后账号链路异常，可通过发布热修回退到上一版本（仅微信登录），服务端接口不需要回滚。

## Open Questions

- `/device/app/api/user/username/login` 在客户端的具体业务触发点是否需要首期落地，还是仅预埋仓储接口。
- `bind_device` 是否在登录成功后自动触发，还是仅由用户在账号管理页手动触发。
- `wxId` 在注册与登录返回中的前端展示/存储需求是否存在（当前仅用于联调与日志，不进入 UI）。
- 改密成功后是否要求强制重新登录（当前设计为保持会话，待后端安全策略确认）。
