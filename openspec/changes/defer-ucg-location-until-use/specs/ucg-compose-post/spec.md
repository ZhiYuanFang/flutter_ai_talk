## ADDED Requirements

### Requirement: Compose publish SHALL request UCG location consent before post API

Before calling `createPost` or `updatePost` from `UcgComposeScreen`, the client MUST invoke the UCG location consent flow and pass returned coordinates when available. Denial MUST NOT block publish; the API call MUST proceed without lat/lng.

`UcgComposeScreen` 在调用 `createPost`/`updatePost` 前 MUST 走 UCG 定位同意流程；有坐标则传入；拒绝后 MUST 仍允许发表（无 lat/lng）。

#### Scenario: 新帖发表前申请定位

- **WHEN** 用户在 compose 点击「发表」且媒体上传已完成
- **THEN** App SHALL 先执行定位同意流程
- **AND** 随后 SHALL 调用 `createPost`（lat/lng 可选）

#### Scenario: 拒绝定位仍发表成功

- **WHEN** 用户在发表流程中拒绝定位
- **THEN** App MUST 仍调用 `createPost` 或 `updatePost` 且无 lat/lng
- **AND** App MUST NOT 因拒绝定位而阻止发表

#### Scenario: 编辑更新帖同样走定位

- **WHEN** 用户在编辑模式点击「更新」
- **THEN** App SHALL 在 `updatePost` 前执行相同定位同意流程
