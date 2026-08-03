## Context

`UcgHomeShell` 在喂养页叠放 `UcgEnterCompanionTab`（左）与 `UcgEnterSquareTab`（右）。产品要求删除；横滑进陪伴/UCG 必须保留。

## Goals / Non-Goals

**Goals:**

- 喂养页零拉条 UI；删除挂载与（若无引用）组件文件。
- PageView 在喂养页仍可左右滑切换（除既有 dock/tip 拖动禁滑窗口外）。
- 规格去掉「必须展示拉条」及拉条未读点。

**Non-Goals:**

- 不改三页索引、懒挂载、Clinic/UCG WS 生命周期。
- 不改 tip「对话」进陪伴。
- 不在喂养页另做未读替代入口（未读仍在 UCG 壳）。
- 不禁横滑。

## Decisions

### 1. 只摘挂载 + 删死代码

- **决策**：`ucg_home_shell` 移除 `if (feeding) ...Tabs`；全库确认无引用后删除两个 tab 文件。
- **备选**：`Visibility` 永久 false —— 拒绝，留死代码。

### 2. 横滑保留

- **决策**：不新增 `NeverScrollableScrollPhysics`；既有 `_blockPageScroll`（输入 dock / tip 拖动）逻辑保留。
- **验收**：喂养静止时可滑向左=陪伴、向右=UCG（或反之，以现网 PageView 方向为准）。

### 3. 未读点

- **决策**：拉条未读高亮需求 **REMOVED**；`ucgUnreadCountProvider` 仍服务 UCG 内 Tab，无需为喂养另做红点。

### 4. tip bridge 文案

- **决策**：注入触发改为「横滑或 tip 对话 / pager 请求」，去掉拉条。

## Risks / Trade-offs

- [发现性下降] → 接受；靠横滑 + tip。
- [用户不知可滑] → 产品接受；本变更不做新手引导。

## Migration Plan

- 纯客户端；热更即可。回滚恢复两行挂载与文件。

## Open Questions

- 无（横滑保留已冻结）。
