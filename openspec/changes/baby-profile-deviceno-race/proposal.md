## Why

已登录且本地已有绑定 `deviceNo`、喂养历史可正常加载时，设置中心仍可能显示「尚未绑定宝宝ID」，顶栏却走「已绑定」分支并展示默认昵称「宝宝」与「不满1个月啦」。根因是 `settingsBabyProvider` 在 `deviceNo` 尚未灌入时抢跑加载并缓存空 id 占位画像，随后 `deviceNo` 到位也不会重拉；`GatewayBootstrapGate` 虽再 `loadBaby` 却未刷新该 Provider，造成绑定态与画像态撕裂。

## What Changes

- `settingsBabyProvider`（或等价画像加载）在 `deviceNo` 从空→有、有→空、或标识变更时 **必须** 重新加载宝宝画像，不得长期缓存「未绑定」占位。
- `GatewayBootstrapGate`（或冷启动画像拉取成功路径）在拿到有效画像后 **必须** 使展示用画像 Provider 与之一致（invalidate / 覆写），不得只更新 `babySexProvider`。
- `babyDisplayProvider`：当已登录且 `deviceNo` 非空，但当前画像仍为空 id /「未绑定宝宝ID」占位时， **不得** 误展示「宝宝 · 不满1个月啦」；应视为画像未就绪或仍按未绑定 chrome，直至有效画像到达。
- 设置中心「宝宝信息」与顶栏身份展示在绑定就绪后与真实画像对齐（有绑定则不再误显绑定 CTA / 默认空态月龄）。

## Capabilities

### New Capabilities

- `baby-profile-load`：宝宝画像加载与 `deviceNo` 生命周期绑定；bootstrap 成功后刷新展示 Provider。
- `baby-display-provider`：补充「已绑定但画像仍为占位」中间态的顶栏/设置行为（承接既有 L2 快照能力边界）。

### Modified Capabilities

- （无独立 `openspec/specs/<capability>/` 目录；行为增量以本 change 下 ADDED delta 为准，归档时并入基线。）

## Impact

- 代码：`app/lib/providers/settings_baby.dart`、`baby_display_provider.dart`、`bootstrap/gateway_bootstrap_gate.dart`；可能触及 `remote_settings_repository.dart` 空 `deviceNo` 占位语义说明。
- 关联：承接 `baby-display-provider` / `identity-header-auth-states`；不改网关 API、不改绑定流程本身。
- 验证：手工冷启动已绑定账号 → 设置中心见真实宝宝卡、顶栏见真实昵称/月龄；无新测试文件。
