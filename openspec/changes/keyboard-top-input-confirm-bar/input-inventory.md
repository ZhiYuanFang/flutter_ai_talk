# 输入入口清单（任务 1.1）

## 页面输入

- 首页文本输入
  - 位置：`app/lib/ui/home_screen.dart`
  - 控制器：`_webController`
  - 提交流程：`_onTextSubmit()`
- 登录页账号
  - 位置：`app/lib/ui/login_screen.dart`
  - 控制器：`_accountCtrl`
  - 提交流程：确认后切换到密码输入焦点
- 登录页密码
  - 位置：`app/lib/ui/login_screen.dart`
  - 控制器：`_passwordCtrl`
  - 提交流程：`_onUsernameLogin()`
- 注册页账号
  - 位置：`app/lib/ui/register_screen.dart`
  - 控制器：`_accountCtrl`
  - 提交流程：确认后切换到密码输入焦点
- 注册页密码
  - 位置：`app/lib/ui/register_screen.dart`
  - 控制器：`_passwordCtrl`
  - 提交流程：确认后切换到确认密码输入焦点
- 注册页确认密码
  - 位置：`app/lib/ui/register_screen.dart`
  - 控制器：`_confirmPasswordCtrl`
  - 提交流程：`_onRegisterUsername()`
- 宝宝绑定页宝宝 ID
  - 位置：`app/lib/ui/baby_bind_screen.dart`
  - 控制器：`_deviceCtrl`
  - 提交流程：确认后失焦（提交由页面主按钮触发）
- 宝宝绑定页宝宝昵称
  - 位置：`app/lib/ui/baby_bind_screen.dart`
  - 控制器：`_nicknameCtrl`
  - 提交流程：确认后失焦（提交由页面主按钮触发）
- 宝宝资料编辑昵称
  - 位置：`app/lib/ui/baby_profile_editor.dart`
  - 控制器：`_nicknameCtrl`
  - 提交流程：确认后失焦（保存由页面按钮触发）

## 弹层/对话框输入

- 设置中心单字段对话框
  - 位置：`app/lib/ui/settings_screen.dart`
  - 控制器：`c`
  - 提交流程：确认后 `Navigator.pop(c.text)`
- 设置中心双字段对话框（字段 1）
  - 位置：`app/lib/ui/settings_screen.dart`
  - 控制器：`c1`
  - 提交流程：确认后切换到字段 2 焦点
- 设置中心双字段对话框（字段 2）
  - 位置：`app/lib/ui/settings_screen.dart`
  - 控制器：`c2`
  - 提交流程：确认后 `Navigator.pop([c1.text, c2.text])`
- 历史编辑备注
  - 位置：`app/lib/ui/home_history_edit_sheet.dart`
  - 控制器：`_remarkCtrl`
  - 提交流程：确认后失焦（保存由页面按钮触发）
- 数值事件备注
  - 位置：`app/lib/ui/home_number_event_sheet.dart`
  - 控制器：`_remarkCtrl`
  - 提交流程：确认后失焦（确认记录由页面按钮触发）

## 统一策略说明

- 所有受管控输入框统一接入 `keyboardInputBridgeController`。
- 统一展示键盘顶部确认条：左侧文本区 + 右侧“确定”按钮。
- 密码场景统一启用脱敏显示：登录密码、注册密码、注册确认密码、设置弹窗中的 `obscureText` 字段。