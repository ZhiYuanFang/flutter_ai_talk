## Why

预约卡点「上次」已能经不限窗 filter 拿到真 `HistoryRecord`，但 `showHomeHistoryEditSheet` 只用 id 回查 `homeHistoryProvider` 近窗列表；窗外记录一开 sheet 就 toast「记录不存在」并关闭。需要让编辑 sheet 信任传入的种子 record，保存/删除以 API 为准，不强行塞进喂养近窗（本地可暂不见）。

## What Changes

- `showHomeHistoryEditSheet` / `_resolveRecord`：近窗命中用列表行；**未命中则用调用方传入的种子 `HistoryRecord`** 起表，MUST NOT 再因「列表无此 id」直接弹「记录不存在」并 pop。
- 保存/删除：仍走既有 update/delete API；若该 id 本就不在 `homeHistory`，成功后 **不得** 仅为同步而强制 insert 进近窗（replace/remove 无键则 noop）；WS 后续到达再入列即可。
- 预约卡上次点按路径因此可真正打开编辑（补齐 `appointment-card-last-label-edit-on-tap` 缺口）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-history-edit-sheet`：支持种子 record；窗外记录可编辑；保存/删除以 API 为准、近窗可暂不见。
- `appointment-event-client`：点按上次再拉后开 sheet 时，窗外记录 MUST 能完成编辑流（不再因近窗缺失失败）。

## Impact

- UI：`home_history_edit_sheet.dart`（resolve / 可选种子参数）。
- 调用方：预约卡上次编辑已传完整 record，一般只需 sheet 侧改动。
- 无新 Go API；无强制改 home 列表排序/分页。
