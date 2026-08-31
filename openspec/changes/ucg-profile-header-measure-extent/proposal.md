## Why

`UcgProfileShell` 折叠头用魔法 `maxExtent`（主人 `248` 等），卡内加「我的邀请码」等行后内容超出被 `Clip.hardEdge` 裁切；加一行就裁已经不止一次。需要改为内容测高驱动 `maxExtent`，去掉手写固定块高，并在异步测高完成前用占位高度避免闪屏。

## What Changes

- 折叠资料头 `SliverPersistentHeader.maxExtent` **MUST** 由资料卡实际布局高度推导（toolbar + pad + 测得卡高），**不得**再依赖主人 `248` / 访客手估块高等魔法固定展开高作为最终真相。
- 测高可异步（首帧 / 内容变更后）；完成前 **MUST** 使用稳定占位 `maxExtent`，避免头高从过小跳到正确值造成明显闪屏或列表跳动。
- 内容变化（bio、邀请行、wxBound、访客操作行等）导致卡高变化时 **MUST** 重新测高并更新 `maxExtent`。
- 保留 pinned 折叠与头像 morph；不改邀请业务语义。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- `ucg-profile-header-extent`: 资料折叠头展开高度由测高驱动、占位防闪、内容变更重测，禁止魔法固定高作为最终值。

### Modified Capabilities

- （无）基线 `ucg-profile` 的折叠/morph/双 Tab 语义不变；本变更只约束展开高度来源。实现落在同一 `UcgProfileShell`。

## Impact

- 主改：`app/lib/ucg/ui/ucg_profile_shell.dart`（`_headerExpandedHeight`、`_UcgProfileHeaderDelegate`、测高/占位状态）。
- 可能触及 `UcgProfileOwnerHeaderCard` / 测高用 offstage 副本。
- 无后端 API；无 Android 原生。
