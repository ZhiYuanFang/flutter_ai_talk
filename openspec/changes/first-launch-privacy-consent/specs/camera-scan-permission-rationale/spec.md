## ADDED Requirements

### Requirement: 宝宝共享扫码申请相机前须用途说明

Before requesting the system camera permission on the baby-share QR scan screen, the client MUST show an in-app purpose disclosure when permission is not yet granted. 在宝宝共享扫码页，当相机权限尚未授予时，客户端必须在调用系统 `Permission.camera`（或等价）申请**之前**展示应用内用途说明；已授权时可不展示用途框并直接进入扫码。

#### Scenario: 未授权时先用途框再系统申请

- **WHEN** 用户进入宝宝共享扫码页且相机权限未授予
- **THEN** 系统必须先展示用途说明（说明用于扫描宝宝共享码以加入家庭共享），用户确认后才可弹出系统相机权限请求

#### Scenario: 用途框取消不申请系统权限

- **WHEN** 用户在相机用途说明中选择取消或不继续
- **THEN** 系统**不得**调用系统相机权限申请，且不得进入可用扫码预览态

#### Scenario: 已授权跳过用途框

- **WHEN** 用户进入宝宝共享扫码页且相机权限已授予
- **THEN** 系统可以不展示用途说明框，并直接进入扫码就绪态
