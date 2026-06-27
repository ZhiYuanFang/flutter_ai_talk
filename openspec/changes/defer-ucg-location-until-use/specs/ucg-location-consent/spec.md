## ADDED Requirements

### Requirement: UCG location consent SHALL gate coordinate reads with stated purpose

The client MUST expose a single UCG location consent entry (e.g. `ensureUcgLocationForDistance`) used before reading device coordinates for UCG feed/post APIs. On native mobile, when permission is not yet granted and the user has not denied location for the current app process, the client SHALL show an in-app rationale dialog stating that location is used to display distance to posts (e.g.「用于展示动态与你的距离；拒绝后仍可使用，只是不显示距离」) before calling the system location permission request. On Web, the helper MUST return null without prompting.

客户端 MUST 提供统一的 UCG 定位同意入口；原生端在未授权且本进程尚未拒绝时，必须先展示用途说明对话框，再调用系统定位权限；Web MUST 直接返回 null。

#### Scenario: 首次进入需定位场景展示说明

- **WHEN** 用户在原生 App 首次触发需坐标的 UCG 操作且 `checkPermission` 为 denied
- **THEN** App SHALL 先展示 in-app 用途说明对话框
- **AND** 用户确认后才 SHALL 调用系统 `requestPermission`

#### Scenario: 本进程已拒绝不再弹系统框

- **WHEN** 用户在本 App 进程内已拒绝定位且再次触发需坐标的 UCG 操作
- **THEN** App MUST NOT 再次调用 `requestPermission`
- **AND** App SHALL 返回 null 坐标并继续无 lat/lng 的 API 调用

#### Scenario: 永久拒绝仅引导设置

- **WHEN** `checkPermission` 为 deniedForever
- **THEN** App MUST NOT 调用 `requestPermission`
- **AND** App SHALL 返回 null 坐标

### Requirement: Square entry SHALL offer settings hint after location denial

When the user has denied UCG location for the current process or has `deniedForever`, and the user enters the UCG square tab with no available coordinates, the client SHALL display a non-blocking「去设置」 affordance (banner, chip, or equivalent) on the square surface. Tapping it MUST open system app settings. The client MUST NOT block feed loading while the hint is shown.

当用户已拒绝定位并进入广场 Tab 且无可用坐标时，客户端 MUST 在广场界面展示非阻塞的「去设置」入口；点击 MUST 跳转系统设置；Feed 加载 MUST NOT 被阻断。

#### Scenario: 拒绝后进广场展示去设置

- **WHEN** 用户在本进程内拒绝定位后进入 UCG 广场 Tab
- **THEN** App SHALL 展示「去设置」入口
- **AND** App SHALL 仍加载推荐 Feed（无 lat/lng）

#### Scenario: 点击去设置

- **WHEN** 用户点击「去设置」
- **THEN** App MUST 打开系统 App 设置页
