# disable-default-input-autofocus 回退说明

## 回退目标

当出现输入不可用、键盘无法弹出或焦点行为异常时，快速恢复旧焦点策略。

## 回退步骤

1. 回退路由级焦点清理：
   - 恢复 `app/lib/router/app_router.dart` 中的观察器改动。
   - 移除 `app/lib/router/focus_cleanup_observer.dart` 的注册。
2. 回退弹窗输入行为：
   - 恢复 `app/lib/ui/widgets/app_glass_overlay.dart` 中必要的焦点策略（如业务确需）。
3. 按页面验证：
   - 登录、注册、首页、设置弹窗、历史编辑逐项验证输入可用性。

## 回退后检查

- 进入/返回页面是否恢复旧行为。
- 用户点击输入框是否可正常聚焦与提交。
- 键盘顶部确认条和提交链路是否正常。
