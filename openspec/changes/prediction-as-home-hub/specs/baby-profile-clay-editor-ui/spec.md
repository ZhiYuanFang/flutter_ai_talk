## ADDED Requirements

### Requirement: Baby profile form SHALL show centered avatar above nickname

The baby profile editor form SHALL display the baby avatar horizontally centered above the nickname field. Tapping that avatar MUST open a local image picker (gallery and/or camera consistent with history event image picking). After a successful pick, the form MUST show the new local image (pending or after save per design) using the baby-avatar-local store.

宝宝信息表单 **必须** 在昵称上方横向居中展示头像；点击头像 **必须** 可选择本地图片（流程对齐事件图片选图）；选中后 **必须** 经宝宝头像本地存储展示。

#### Scenario: 昵称上方居中头像

- **WHEN** 用户打开编辑宝宝信息页且资料加载成功
- **THEN** 主卡片内 MUST 在「宝宝昵称」区块上方居中展示头像（自定义或默认占位）

#### Scenario: 点击头像选图

- **WHEN** 用户点击表单中的宝宝头像并成功选择一张本地图片
- **THEN** 头像展示 MUST 更新为该本地化副本（或等价即时预览后落盘）
