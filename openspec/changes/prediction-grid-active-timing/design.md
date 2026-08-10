## Context

网格 compact 卡主区现为「大 Logo + `nextAt` 倒计时」；喂养历史已有进行中计时识别与停止。预测页加事件有计时中守卫，但卡面仍显示预测倒计时。产品：仅 compact；计时中留推演开关；列表不改。

## Goals / Non-Goals

**Goals:**

- compact + 该事件有 active timing → 专用布局（名左侧小图、中间 elapsed、底停止、保留推演开关）。
- 停止语义对齐喂养（无确认、写 endTime）。
- 计时中不展示 nextAt 倒计时/大图主区。

**Non-Goals:**

- 不改列表态（`!compact`）折线卡。
- 不改推演开关持久化/置灰语义（计时中仍可开关）。
- 不新建测试文件。

## Decisions

1. **匹配规则**  
   在 `homeHistoryProvider.items` 中找 `isActiveTimingRecord` 且 `eventId`（或与卡行一致的事件键）匹配当前预测行；多条时取最新一条（与喂养守卫一致优先）。

2. **布局（compact + active）**  
   ```
   [Logo] 事件名 … [推演 Switch]
   [居中大号 elapsed]
   [停止 Button]
   ```  
   无倒计时大图、无「超时 …」相对行（计时中不适用逾期倒计时）。

3. **刷新**  
   `predictionClockProvider` 驱动 elapsed；停止 in-flight 用本地 Set（recordId）防连点。

4. **停止实现**  
   优先抽共享 `stopActiveTimingRecord(ref, record)`（或 prediction 内联等价调用）对齐 `HomeScreen._stopActiveTimer`；成功后 `homeHistoryProvider` 即时替换，卡自动退出计时 chrome。

5. **手势**  
   Stop 使用独立 `onPressed`，外层 `InkWell(onCardTap)` 在 active 时对停止区域不可穿透；整卡 tap 在 active 时可不触发加事件（或依赖既有守卫 toast）。

6. **规格**  
   MODIFIED 网格倒计时 Requirement：排除「存在进行中计时」；ADDED 计时中 chrome Requirement。

## Risks / Trade-offs

- [历史未同步] 本地无进行中行则仍显示倒计时 → 可接受；与喂养一致依赖历史。  
- [停止逻辑重复] 不抽出则双份漂移 → tasks 优先抽共享或明确复制并注释对齐点。

## Migration Plan

- 纯 UI/客户端。回滚：去掉 active 分支即可。

## Open Questions

（无；开关保留、仅网格已确认。）
