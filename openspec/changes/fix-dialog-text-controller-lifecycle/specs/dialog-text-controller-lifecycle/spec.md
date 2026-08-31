## ADDED Requirements

### Requirement: Dialog-owned text editing controller lifecycle

凡经 `showDialog`、`showGlassDialog`、`showModalBottomSheet` 或等价路由展示、且内含由调用方意图拥有的 `TextField` / `TextFormField` 的弹层，客户端 MUST 将对应的 `TextEditingController`（以及由该弹层创建的 `FocusNode`，若有）交由弹层子树的 `State`（或在该路由完全卸载之后）创建与释放。客户端 MUST NOT 在 `await` 上述展示 API 返回后、弹层退场动画仍可能重建输入控件时立即 `dispose` 该 controller。

#### Scenario: Invite redeem dismiss without disposed-controller assert

- **WHEN** 用户在开通中心打开「输入邀请码」弹窗并点击「兑换」或「取消」（或可关闭时点遮罩），且系统执行关闭动画
- **THEN** 客户端 MUST NOT 抛出 `TextEditingController was used after being disposed`，且兑换确认路径在用户提交有效码时仍 MUST 发起既有兑换请求（或取消时 MUST NOT 误兑）

#### Scenario: New dialog with text field follows ownership rule

- **WHEN** 新增带文本输入的 dialog / glass overlay / modal bottom sheet
- **THEN** 实现 MUST 将 `TextEditingController` 生命周期绑定到弹层 `State.dispose`（或路由卸载后释放），且 `openspec/project.md` MUST 记载该约定供后续变更对照
