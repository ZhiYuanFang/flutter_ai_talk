## Context

`smart-prediction-appointment-accuracy-ux` 已落地预约 next remark、竖列表藏预约卡等。联调暴露：① 预约 sheet 备注被键盘盖住；②「上一次」仍吃近 7 日窗 / tip，缺 remark。Go `GET /device/history/api/filter` 已支持 `ignoreTimeRange` + `eventIds` + `limit`，按 id 倒序；Flutter 尚未传该参数。`event/latest` 为整机最近一条，不适用。

## Goals / Non-Goals

**Goals:**

- 备注获焦 / 键盘升起：收起预约时间滚轮；输入框按新增事件同族避让（inset + keyboardLift）。
- 失焦 / 键盘收起：恢复滚轮。
- 预约卡「上一次」：filter 不限窗取最近一条（时间 + history remark）。
- Repository 补 `ignoreTimeRange`。

**Non-Goals:**

- 新 Go latest 接口；改 `event/latest` 契约。
- 非预约预测卡 lastAt / 7 日 range 推演窗。
- 改预约 nextAt/remark PUT 契约。

## Decisions

1. **不新造 Go API**  
   复用 `filter?eventIds=<根及子>&limit=1&ignoreTimeRange=true`。`event/latest` 禁止用于本场景。

2. **eventIds 范围**  
   预约根 + catalog 子 id（history 常打在叶子）。仅根 id 可能空结果。

3. **触发**  
   瀑布预约卡需要「上一次」时拉取（single-flight / 短缓存按根）；成功则覆盖展示用 lastAt+remark；失败可回退窗内/tip 时间但 remark 不得假造。

4. **键盘 + 滚轮**  
   `respectKeyboardInset: true`；备注 `keyboardLiftTarget`；`FocusNode` 监听：有焦或 `viewInsets.bottom>0` 时隐藏/收起四列滚轮，失焦且键盘收起后恢复。年份行可保留。不强制上完整 KeyboardInputBridge（可选，非目标）。

5. **排序语义**  
   接受 Go id DESC 为「最近一次」权威；不在客户端再按 startTime 重排（除非后续产品要求）。

## Risks / Trade-offs

- [id DESC ≠ startTime 最新] → 补录极端偏差；接受与 Go filter 一致。  
- [收起滚轮后改时间] → 失焦即恢复；改约仍可用。  
- [每卡一次 filter] → single-flight + 按根缓存，避免瀑布连打。

## Migration Plan

1. 接线 `ignoreTimeRange` → 预约 last 拉取 → sheet 键盘/滚轮。  
2. 真机：久未记录的预约卡有上次+备注；备注获焦滚轮收起且输入可见。  
3. 回滚：去掉 ignore 拉取与 sheet 焦点逻辑即可。

## Open Questions

- 无（范围仅预约；Go 能力已确认）。
