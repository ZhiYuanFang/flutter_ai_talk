# 首批接入验收基线（任务 1.2）

## 范围

- 首页文本输入（`home_screen`）
- 登录页（`login_screen`）
- 注册页（`register_screen`）

## 通过标准

### A. 键盘不顶起

- 当输入框聚焦并弹出键盘时，页面主内容区域不得整体上移跳动。
- 首批接入页面 `Scaffold` 使用稳定布局策略（`resizeToAvoidBottomInset: false`）。

### B. 确认回填

- 当用户通过键盘顶部确认条输入并点击“确定”后，目标 `TextEditingController` 内容与确认条文本一致。
- 焦点切换场景（如账号 -> 密码）必须保留回填结果。

### C. 提交触发

- 首页文本输入点击“确定”后触发 `_onTextSubmit()`。
- 登录密码点击“确定”后触发 `_onUsernameLogin()`。
- 注册确认密码点击“确定”后触发 `_onRegisterUsername()`。

### D. 密码脱敏

- 登录密码、注册密码、注册确认密码在确认条中不得明文显示。

## 验证记录模板

- 平台：Android / iOS
- 页面：Home / Login / Register
- 结果：通过 / 失败
- 失败现象：
- 复现步骤：
- 备注：