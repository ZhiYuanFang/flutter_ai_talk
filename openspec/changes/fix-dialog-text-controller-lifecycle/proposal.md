## Why

开通中心「输入邀请码」点兑换后崩溃：`TextEditingController was used after being disposed`。根因是在 `showGlassDialog` / `showDialog` 的 Future 刚返回时就 `dispose` controller，而弹窗退场动画仍在重建 `TextField`。后续凡带输入框的弹框若不统一规范，会重复踩坑。

## What Changes

- 修复 `feature_unlock_hub_screen` 邀请码弹窗：controller 归 dialog body 的 `State` 生命周期管理（对齐已有 `_GlassTextConfirmDialogBody`）。
- 全仓审计：弹窗外创建 + await 结束后 dispose 的同类反模式一并修掉。
- 在 `openspec/project.md` 增加**弹框 TextEditingController 生命周期**工程约定，后续新弹框 MUST 遵守。
- 不改兑换 API / 业务语义；取消与兑换仍返回既有结果。

## Capabilities

### New Capabilities

- `dialog-text-controller-lifecycle`：带文本输入的 dialog / glass overlay 中，`TextEditingController`（及同类 `FocusNode` 若由弹框拥有）的创建与 dispose 归属。

### Modified Capabilities

- （无）行为基线无既有 capability 专述此 UI 契约；以新 capability 收录。

## Impact

- 代码：`app/lib/ui/feature_unlock_hub_screen.dart`；审计命中的其它 dialog 入口；参考范例 `app_glass_overlay.dart` 的 `_GlassTextConfirmDialogBody`。
- 文档：`openspec/project.md` 新增约定段落。
- 无 API / 原生权限 / WebSocket 变更；不新建 `**/test/**`。
