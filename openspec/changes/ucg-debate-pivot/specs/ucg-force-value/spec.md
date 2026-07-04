## ADDED Requirements

### Requirement: Force value SHALL persist on wx profile and expose in author DTOs

The backend MUST store `force_value` (non-negative integer) on the wx user record. Feed and profile author objects MUST include `forceValue`. Tier MAY be computed server-side as `forceTier` or client-side from `forceValue` using frozen thresholds.

后端 MUST 在 wx 表存储 `force_value`；Feed 与 profile 作者 DTO MUST 返回 `forceValue`。

#### Scenario: Feed 作者含原力

- **WHEN** 客户端加载辩论 Feed
- **THEN** 每项 `author` SHALL 含 `forceValue` 字段

### Requirement: Force tier icons SHALL follow frozen thresholds with no placeholder below bronze

Tier mapping MUST be: `[0,500)` → none (no icon, no placeholder space); `[500,1000)` → bronze; each additional 500 → next tier through diamond. UI MUST render the tier icon only when tier ≥ bronze.

档位：[0,500) 无图标无占位；[500,1000) 青铜；每 +500 升档至钻石。

#### Scenario: 低于 500 不展示

- **WHEN** 作者 `forceValue` 为 499
- **THEN** UI MUST NOT 渲染原力图标或空白占位

#### Scenario: 青铜展示

- **WHEN** 作者 `forceValue` 为 500
- **THEN** UI SHALL 在广场作者昵称旁与个人页「关注 N」左侧展示青铜图标

#### Scenario: 每 500 升档

- **WHEN** 作者 `forceValue` 为 1500
- **THEN** tier SHALL 对应第三档（银）图标
