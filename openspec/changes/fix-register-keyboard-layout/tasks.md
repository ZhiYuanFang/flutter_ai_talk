## 1. 注册页布局对齐登录页（`account-registration`）

- [x] 1.1 在 `register_screen.dart` 将滚动子树内主 `Column` 设为 `mainAxisAlignment: MainAxisAlignment.end`，与 `login_screen.dart` 一致
- [x] 1.2 使用 `Stack` 将返回 `IconButton` 浮于左上角，移出贴底表单 Column，避免占用顶对齐垂直空间
- [x] 1.3 统一表单水平/底部内边距与登录页（水平 40、底部 24 + `bottomInset`），移除与登录页不一致的顶对齐 `SizedBox` 挤压
- [x] 1.4 确认三字段 `keyboardLiftTarget`、焦点链（next → 确认密码）、校验与提交逻辑未改动

## 2. 验证

- [x] 2.1 在 `app/` 运行 `flutter analyze`，无新增 error
- [ ] 2.2 运行现有 `registration_flow_test.dart`，确保 finder 仍通过
- [ ] 2.3 Android 14 真机走查：注册页依次聚焦账号、密码、确认密码，确认密码可持续输入且不卡死
- [ ] 2.4 Android 14 真机走查：密码框键盘「下一项」进入确认密码，行为与点击聚焦一致
- [ ] 2.5 对比登录页：注册页表单贴底视觉与登录页一致，返回按钮可正常返回
