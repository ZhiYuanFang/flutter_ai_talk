## ADDED Requirements

### Requirement: Profile collapsing header maxExtent SHALL be driven by measured card height

The `UcgProfileShell` collapsing header (`SliverPersistentHeader` / equivalent) MUST set its expanded `maxExtent` from the **measured** height of the expanded profile card content plus the pinned toolbar height and flexible top padding. After a successful measurement, the client MUST NOT use owner magic constants (e.g. `248`) or visitor hand-estimated block sums as the final `maxExtent`. Adding rows inside the card (e.g. invite entry) MUST increase measured height and `maxExtent` so the card is NOT clipped by the header’s hard clip.

资料折叠头展开 `maxExtent` **必须** 由实测资料卡高度 + toolbar + 顶垫推导；测高成功后 **不得** 再用主人魔法高或访客手估块高作终值；卡内加行 **必须** 反映到 `maxExtent`，**不得** 被硬裁切。

#### Scenario: 邀请行完整可见

- **WHEN** 主人已绑定微信且资料卡含「我的邀请码」入口行
- **THEN** 展开态折叠头 MUST 完整展示该行（含标题与副文案可视区域）
- **AND** MUST NOT 因固定 maxExtent 过矮而裁切该行

#### Scenario: 测高后不以 248 为终值

- **WHEN** 主人资料卡已完成至少一次成功测高
- **THEN** `maxExtent` MUST 等于 toolbar + flexibleTopPad + 实测卡高（允许亚像素舍入）
- **AND** MUST NOT 仅因历史常量 `248` 而截断更高内容

#### Scenario: 访客 bio 变高同步 maxExtent

- **WHEN** 访客资料卡因简介等导致实测高度变化且测高成功
- **THEN** 折叠头 `maxExtent` MUST 更新为与新实测一致

### Requirement: Async header measure SHALL use a placeholder maxExtent to avoid flash

Until the first successful card-height measurement for the current profile layout inputs, the client MUST apply a **placeholder** `maxExtent` that is stable and MUST NOT be intentionally shorter than the typical expanded card (so the header does not flash from a too-short clip to the correct height). After measurement succeeds, the client MUST switch to the measured `maxExtent`. When layout inputs change (including async invite summary affecting card height), the client MUST remeasure; during remasure the previous measured height MAY remain until the new measure commits, to avoid a short flash.

在首次成功测高前，客户端 **必须** 使用稳定占位 `maxExtent`，**不得** 故意使用过矮占位导致先裁后撑的闪屏；测高成功后 **必须** 切到实测值；输入变更须重测，重测期间 MAY 保持上一实测值直至新值提交。

#### Scenario: 冷启无过矮闪裁

- **WHEN** 用户打开「我的」资料且测高尚未完成
- **THEN** 折叠头 MUST 使用占位 `maxExtent`
- **AND** MUST NOT 先以明显过矮高度展示以致资料卡底部被裁后再跳到全高

#### Scenario: 邀请异步变高不闪回矮高度

- **WHEN** 邀请摘要从 loading 变为 data 导致卡高增加
- **THEN** 客户端 MUST 重测并更新 `maxExtent`
- **AND** 更新过程 MUST NOT 先回退到过矮占位再升高（可保持旧实测直至新实测）

### Requirement: Profile header measure MUST preserve collapse morph behavior

Pinned collapse to the mini toolbar and avatar morph driven by `shrinkOffset` relative to `(maxExtent - minExtent)` MUST remain. Changing `maxExtent` via measure MUST NOT remove the collapsing header or show nickname in the collapsed toolbar (baseline `ucg-profile` collapse chrome unchanged).

测高改 `maxExtent` **必须** 保留 pinned 折叠与头像 morph；折叠顶栏仍 **必须 NOT** 显示昵称（与基线一致）。

#### Scenario: 仍可折叠到仅小头像

- **WHEN** 用户在资料页向上滚动至折叠完成
- **THEN** 顶栏 MUST 仍为居中缩小头像形态（无昵称）
- **AND** 展开态曾完整显示的资料卡内容在滚动过程中按既有 opacity/morph 收起
