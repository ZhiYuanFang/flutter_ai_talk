## MODIFIED Requirements

### Requirement: ManagedKeyboardTextField SHALL pass KeyboardOverlayConfig to bridge

The component MUST accept `KeyboardOverlayConfig` (or derive it via `scene`) and pass it to `keyboardInputBridgeController.attach`. When `showInputField` is true in config, the page TextField MUST be read-only display while editing; when false, the page TextField MUST remain editable.

受管控输入组件必须透传可组合浮层配置；浮层主编辑时页面只读，否则页面可编辑。

#### Scenario: compose 页面可编辑
- **WHEN** `ManagedKeyboardTextField` 以 `ucg.compose.body` attach 且 config 无浮层输入
- **THEN** 页面 TextField SHALL 可编辑
- **AND** SHALL NOT 设为 readOnly

#### Scenario: 评论页面只读
- **WHEN** `ManagedKeyboardTextField` 以 `ucg.post.comment` attach 且 config 含浮层输入
- **THEN** 页面可见输入 SHALL 只读展示
- **AND** 浮层 TextField SHALL 为主编辑面

### Requirement: Managed field SHALL register anchor for component lift

When attaching, the component MUST register an anchor (`GlobalKey` or equivalent) with the bridge for component lift scrolling.

attach 时必须向 bridge 注册锚点以供顶组件滚动。

#### Scenario: 资料编辑注册锚点
- **WHEN** 用户开始编辑 `ucg.profile.nickname`
- **THEN** bridge SHALL 持有昵称展示/输入区锚点
- **AND** 键盘弹出后该锚点 SHALL 不被浮层遮挡

## ADDED Requirements

### Requirement: Scene resolver SHALL provide default KeyboardOverlayConfig

The client MUST implement `resolveOverlayConfig(String scene)` returning defaults per design scene table unless explicitly overridden at attach time.

必须提供 scene 默认 config 解析，除非 attach 显式 override。

#### Scenario: auth 与宝宝资料 scene 无浮层
- **WHEN** attach scene 为 `login.account`、`change-password.old` 或 `baby-profile.nickname`
- **THEN** 默认 config SHALL 四项均为 false（不渲染全局浮层）
- **AND** 页面输入 SHALL 直接可编辑

#### Scenario: home.text 发送文案
- **WHEN** attach scene 为 `home.text`
- **THEN** 默认 `confirmLabel` SHALL 为「发送」
- **AND** `showEmoji` SHALL 为 true
