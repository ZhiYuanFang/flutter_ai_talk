## Context

`RegisterScreen` 与 `LoginScreen` 共用 `auth_field_scroll.dart`、`keyboard_lift.dart` 及 `inlineAuthScrollMinHeight`。登录页在 `ConstrainedBox(minHeight: viewportHeight)` 内使用 `Column(mainAxisAlignment: MainAxisAlignment.end)`，表单贴视口底部；注册页使用默认顶对齐，顶部有返回按钮，且确认密码下方还有注册按钮、返回链接与隐私协议。

在 Android 14 + 厂商 IME 上，聚焦确认密码时：`bottomInset` 增大 → `padding.bottom` 增大 → `maxScrollExtent` 变化 → `scheduleInlineAuthScrollOnInset`（在 build 内）与 `performKeyboardLift` 多重 `animateTo` 叠加，主线程阻塞，表现为输入卡死或 ANR。

约束：遵循 `v2.0.2` 基线；不新增测试文件（仓库规则）；方案 A 仅改注册页布局，不动全局键盘模块。

## Goals / Non-Goals

**Goals:**

- 注册页主表单与登录页采用相同的贴底 Column 策略，使最低输入框（确认密码）在键盘弹出时所需滚动量与登录页密码框同级。
- 保留返回入口、三字段校验、隐私协议展示与现有视觉组件。
- 在 Android 14 真机上确认密码可稳定聚焦、输入、提交。

**Non-Goals:**

- 重构 `keyboard_lift.dart` 的 inset 反馈环（方案 B）。
- 修改 `AndroidManifest` 的 `windowSoftInputMode` 或 targetSdk。
- 改动登录页、改密页、绑定宝宝等其它 auth 页。
- 为注册页接入 `ManagedKeyboardTextField` / 键盘顶部确认条（auth 内联输入场景已明确豁免浮层）。

## Decisions

### 1. 贴底 Column 对齐登录页

将注册页 `ConstrainedBox` 子 `Column` 设为 `mainAxisAlignment: MainAxisAlignment.end`，与 `login_screen.dart` 一致。`inlineAuthScrollMinHeight` 返回 `viewportHeight` 时，多余空间留在顶部，表单自然靠近底部，与登录页已验证行为一致。

**备选**：仅增加 `bottom padding` 魔法数字 → 拒绝，不同 DPI/字号难维护。

**备选**：`resizeToAvoidBottomInset: true` → 拒绝，与 auth 页统一策略及 `keyboard-top-input-confirm-bar` 内联输入约定冲突。

### 2. 返回按钮用 Stack 浮层

顶对齐 Column 改为贴底后，返回 `IconButton` 不应再作为 Column 首子项占用垂直空间。使用 `Stack`：`SingleChildScrollView` 为底层，返回按钮 `Positioned(top: 0, left: 0)` 浮于 SafeArea 内，行为与常见二级页一致。

内边距：登录页表单区为 `padding: EdgeInsets.fromLTRB(40, 0, 40, 24)`；注册页水平 `40` 保持一致，底部 `24` 与登录对齐（替换当前仅 `16 + bottomInset` 的差异化，可在 `padding` 中统一 `24 + bottomInset`）。

### 3. 不改 keyboard_lift 调度点

本次不移动 `scheduleInlineAuthScrollOnInset` 出 build、不减少 retry。贴底布局预期使确认密码聚焦时 `targetBottom <= liftLine` 更快成立，足以消除注册页特有问题。若回归后仍有个别机型抖动，再单独立项方案 B。

### 4. 隐私协议保留在表单 Column 内

协议文案随表单贴底排列在注册按钮下方，与登录页隐私/第三方登录区位置类比。键盘聚焦确认密码时，lift 目标为确认密码锚点底边，不强制露出协议（与登录页聚焦密码时不强制露出微信登录区一致）。

## Risks / Trade-offs

- **[Risk] 小屏设备表单贴底后顶部空白变大** → 与登录页一致，属可接受产品形态；返回按钮仍可达。
- **[Risk] Stack 返回按钮与滚动内容重叠** → 返回按钮固定于 Stack 顶层，ScrollView 顶部留 `SizedBox` 或与登录页等效的上边距，避免遮挡 logo。
- **[Risk] 仅布局修复无法覆盖全部厂商 IME** → 任务含 Android 14 真机走查；未通过再升级方案 B。

## Migration Plan

纯客户端 UI 布局变更，无数据迁移。发布后即生效；回滚为还原 `register_screen.dart` 布局。

## Open Questions

- 注册页账号、密码字段在现网是否均已正常？（假设是，仅确认密码失败。）
- 是否需要在平板横屏单独验证？（本次与登录页同等处理，不单独加 spec。）
