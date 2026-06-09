## MODIFIED Requirements

### Requirement: UCG managed inputs SHALL support Unicode emoji insertion at cursor

UCG and eligible feeding managed inputs MUST allow Unicode emoji insertion at the current selection. Insertion MAY occur via global overlay emoji panel when `showEmoji` is true, or via inline dock emoji panel for `ucg.chat`. Inserted emoji MUST be plain UTF-8 text in the bound controller.

UCG 与符合条件的喂养输入必须支持 Unicode emoji；入口为全局浮层或聊天 dock，视 config 而定。

#### Scenario: compose 经浮层 emoji 插入
- **WHEN** 用户在 `ucg.compose.body` 打开全局 emoji 面板并点选 emoji
- **THEN** 系统 SHALL 在正文 controller 当前选区插入 emoji

#### Scenario: 聊天经 dock emoji 插入
- **WHEN** 用户在 `ucg.chat` 打开 dock 下方 emoji 面板并点选 emoji
- **THEN** 系统 SHALL 在消息 controller 当前选区插入 emoji
- **AND** 全局浮层 SHALL NOT 展示

## REMOVED Requirements

### Requirement: Emoji toggle SHALL appear ONLY on keyboard-top confirm bar accessory

**Reason**: `ucg.chat` 改为 dock 内 emoji；其他 scene 按 config 决定浮层是否展示 emoji。

**Migration**: 见 `KeyboardOverlayConfig.showEmoji` 与 `ucg-chat-ui` dock 条款。

### Requirement: Confirm bar SHALL remain visible during emoji panel mode

**Reason**: 仅适用于 `anyEnabled` 全局浮层 binding；聊天无全局浮层，dock 面板自行保持可见。

**Migration**: 全局浮层 emoji 模式可见性见 `keyboard-top-input-confirm-bar` MODIFIED 条款。

## ADDED Requirements

### Requirement: Auth feeding scenes SHALL NOT show overlay emoji

For scenes `login.*`, `register.*`, `change-password.*`, `baby-bind.*`, and `baby-profile.nickname`, the default overlay config MUST disable all overlay flags (no global overlay).

登录/注册/改密/绑定/宝宝资料等 scene 默认不渲染全局浮层。

#### Scenario: 登录页无浮层
- **WHEN** 用户在登录、改密或宝宝资料昵称输入框聚焦
- **THEN** 全局浮层 SHALL NOT 渲染

### Requirement: Non-auth feeding scenes MAY show overlay emoji

For `home.text`, `home.history-edit.remark`, and `home.number.remark`, the default overlay config MUST set `showEmoji` to true unless explicitly overridden.

非 auth 喂养备注与 Web home.text 默认必须允许浮层 emoji。

#### Scenario: 历史备注 emoji 浮层
- **WHEN** 用户在 `home.history-edit.remark` 聚焦
- **THEN** 全局浮层 SHALL 展示 emoji accessory
- **AND** 页面备注 Field SHALL 保持可编辑
