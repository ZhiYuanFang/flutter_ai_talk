## Context

`showHomeHistoryEditSheet` 只把 `record.id` 交给 body，`_resolveRecord` 强制从 `homeHistoryProvider.items` 解析；失败 toast「记录不存在」。预约不限窗上次点按再拉拿到的 record 常在近窗外，filter 成功仍无法编辑。产品选定方案 A：种子起表 + 仅 API，近窗可暂不见。

## Goals / Non-Goals

**Goals:**

- 近窗有 id → 行为与现网一致（以列表行为准）。
- 近窗无 id、调用方传了完整种子 → 用种子起表，可编辑/保存/删除。
- 保存/删除成功走 API；`replaceRecord` / `remove` 对不在列表的 id 自然 noop（现实现已是 map/filter），不强行 insert。
- 预约上次点按窗外记录可打开并完成编辑，不再「记录不存在」。

**Non-Goals:**

- 不把窗外记录 upsert 进 home 近窗仅为了开 sheet。
- 不改预约 filter / 短文案逻辑（已在 `appointment-card-last-label-edit-on-tap`）。
- 不新增按 id 的单条 GET（种子已是完整 HistoryRecord）。

## Decisions

1. **API 签名**  
   继续 `showHomeHistoryEditSheet(..., record: HistoryRecord)`；body 同时收 `recordId` + 可选 `seedRecord`（或直接传整份 seed）。`_resolveRecord`：先查 home；未命中且 seed 非空且 `seed.id == recordId` → 用 seed；否则仍 toast 失败（防空开）。

2. **列表与种子谁优先**  
   近窗命中优先（可能比 filter 快照更新）。未命中才用种子。

3. **保存后本地**  
   调用既有 `replaceRecord`；id 不在列表则列表不变（「暂不见」）。删除同理 `remove` noop。依赖后续 WS/refresh 入列，本 change 不强制拉全量。

4. **媒体 / 同步广场**  
   种子路径与近窗路径共用既有 `_loadMediaAndSyncPref`；种子 payload 缺媒体时按现逻辑空条即可。

## Risks / Trade-offs

- [保存后喂养页暂不见该条] → 产品接受；WS upsert 或下次刷新可出现。  
- [种子与服务端竞态] → 保存以 API 为准；失败 toast。  
- [误传错误 seed] → 校验 `seed.id == recordId`。

## Migration Plan

纯客户端。回滚恢复「仅近窗可编辑」即可。

## Open Questions

（无；A 已选定。）
