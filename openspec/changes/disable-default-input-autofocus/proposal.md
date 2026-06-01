# Proposal: disable-default-input-autofocus

## Why

当前应用在进入页面或从子页面返回时，部分输入框会被默认聚焦，导致键盘自动弹出，打断用户浏览与操作流程。随着输入场景增多，需要统一“页面进入/返回时不自动唤起键盘”的交互基线，避免误触发和视觉干扰。

## What Changes

- 新增“输入框默认不自动聚焦”行为规范：页面首次进入、路由返回、弹层重新显示时，输入框不得被动获取焦点。
- 统一焦点恢复策略：仅当用户显式点击输入框或业务明确要求时才允许聚焦并弹出键盘。
- 对现有输入页面与弹层进行焦点策略校正，保留原有输入功能和提交逻辑，不改变业务校验规则。
- 增加回归验收标准，覆盖登录、注册、首页、设置弹窗、历史编辑等高频输入路径。

## Capabilities

### New Capabilities

- `disable-default-input-autofocus`: 规范页面进入和返回时输入框焦点行为，确保键盘仅在用户主动操作时弹出。

### Modified Capabilities

- （无）

## Impact

- 影响范围主要在 Flutter UI 层输入组件与页面生命周期处理，包括 `home_screen`、`login_screen`、`register_screen`、`settings_screen`、`home_history_edit_sheet`、`home_number_event_sheet`、`baby_bind_screen`、`baby_profile_editor` 等。
- 可能涉及通用键盘/焦点管理组件与路由切换后焦点清理逻辑。
- 不涉及后端 API、数据模型或网络协议变更。
- 需要补充输入行为回归测试，重点验证“进入/返回不弹键盘”。
