## ADDED Requirements

### Requirement: MAC 与 MCP 接入点字段帮助入口

On the add-binding form, the speaker MAC field and the Xiaozhi MCP endpoint/token field MUST each expose a help control (e.g. `?` icon). Tapping the control MUST open a field-explanation surface with short copy and instructional images so the user can see where to copy the value in the Xiaozhi console. 添加表单中 MAC 与 MCP 接入点字段旁 **必须** 提供帮助入口，点击后展示说明与步骤图。

#### Scenario: 打开 MAC 帮助

- **WHEN** 用户在添加表单点击 MAC 字段帮助
- **THEN** 客户端 MUST 展示如何从「小智控制台」智能体「设备」列表获取 MAC 的说明
- **AND** MUST 展示本地图 `assets/images/mac_1.png` 与 `assets/images/mac_2.png`（顺序对应进入设备页 → 定位 MAC）

#### Scenario: 打开 MCP 接入点帮助

- **WHEN** 用户在添加表单点击 MCP 接入点/token 字段帮助
- **THEN** 客户端 MUST 展示如何从智能体「配置」→「扩展能力」→「MCP接入点」复制接入点的说明
- **AND** MUST 展示本地图 `assets/images/token_1.png` 与 `assets/images/token_2.png`（顺序对应进入配置 → 复制接入点）

#### Scenario: 帮助不泄露完整 token

- **WHEN** 用户查看字段帮助页
- **THEN** 帮助内容 MUST NOT 写入或回显用户已输入的完整 mcpToken
- **AND** 步骤图可为控制台截图（含脱敏示例）

### Requirement: 添加表单输入控制器生命周期

Any dialog, glass overlay, or modal sheet used to collect alias / MAC / mcpToken MUST own its `TextEditingController`（and FocusNode if created）in that overlay's `State.dispose`, consistent with `dialog-text-controller-lifecycle`. 含输入的添加弹层 **必须** 由弹层 State 持有并释放 controller。

#### Scenario: 关闭添加表单无 disposed 断言

- **WHEN** 用户打开添加表单后取消或提交关闭
- **THEN** 客户端 MUST NOT 抛出 `TextEditingController was used after being disposed`
