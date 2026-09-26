## Context

智能预测页对常规喂养事件用间隔样本推演 `nextAt`，并经 `predict-imminent` 整表同步推送待办。疫苗等事件由预约决定下次时间，后端已提供：

| 契约 | 说明 |
|------|------|
| options `isAppointment` | `0/1` 或等价；缺省非预约 |
| `GET /device/app/api/appointment/next` | `deviceNo`+**根**`eventId` → `{ nextAt }`；无行=`0` |
| `PUT /device/app/api/appointment/next` | upsert；`nextAt=0` 清空（服务端保留行） |
| pending | 仍 `PUT /device/api/predict/imminent/pending`；清空/无约定=**列表移除**该事件；过期正值仍上报 |

本 design 只约束 Flutter；服务端已在孪生仓落地。需求确认结论见 Decisions。

## Goals / Non-Goals

**Goals:**

- 目录识别预约事件并分流预测 UI / 算法（根 eventId）。
- 独立 API 持久化下次约定；编辑页回填/修改/清空；与 history 解耦。
- 正常新增/补充不改原页；空或过期时用专用补约 sheet。
- 与 pending 两步写：记忆（预约表）+ 可推送（pending 含/不含）。

**Non-Goals:**

- 改服务端 predict / 用预约表驱动 Redis。
- 把 `nextAt` 塞进 history 行。
- 复用 `eventType=one` 当预约。
- 修改原有新增记录页面以嵌入下次约定字段。
- 在预测卡或打点后专用 sheet 上提供清空（清空仅编辑页）。

## Decisions

### D1：`isAppointment` 来自 options，缺省 false；eventId 用根

- 与 `EventDefinition.fromOptionsMap` 同路径解析；`1`/`true` 为预约。
- 不得用 `eventType==one` 推断。
- 预约 GET/PUT、预测节点、pending 一律解析为 **catalog 根 id**（子事件标旗亦归到根）。
- `catalogSnapshotsEqual` / 解析落盘 **必须** 含 `isAppointment`，否则缓存不刷新。

### D2：预测分流与过期

```
isAppointment?
  是 → 不展示「补充大概多久一次」；展示「补充下次」
       nextAt>0（含已过期）→ 预测结果=该时间 → 进 pending；UI 对过期标「过期」
       nextAt==0 → 不产生可推送节点；卡仍可展示 +「补充下次」
  否 → 既有间隔预测 + 补充间隔 UI
```

- 预约根 **忽略** `PredictionRecallSeed`（不必强制清库）。

### D3：新增 / 补充不改原页；空或过期弹专用 sheet

- **撤销**「预约新增强制开记录 sheet 并选填 nextAt」。
- 新增：现网 `one` 一键 / `number` sheet / `time` 计时等 **保持原样**。
- 新增或「补充上一次」**成功写 history 后**：若该根 `nextAt==0` 或 `nextAt < now` → 弹出专用下一次预约 sheet；若已是未来时间 → 不弹。
- 关闭专用 sheet（未确认）**无**预约专用语义：保持原 nextAt（空仍空，过期仍过期仍推）。

### D4：专用下一次预约 sheet（设时间，不清空）

```
┌─────────────────────────────────┐
│  {事件logo} 下一次{事件名}预约时间   │
├─────────────────────────────────┤
│  年 | 月 | 日 | 时 | 分  滚动选择   │
└─────────────────────────────────┘
```

- 确认 → PUT 正 `nextAt`（本地墙钟 → unix 秒，与现有 pending 一致）→ 重建预测并 pending 同步。
- 预测卡「补充下次」、打点后引导、编辑页点击修改：**共用**该 sheet。
- **不得**在此 sheet 提供清空。

### D5：编辑 history — 展示、修改、仅此可清

- 打开预约事件任意 history 行：GET 回填同一根 `nextAt` 并展示。
- 点击下次时间 → 打开 D4 sheet 修改。
- **清空**仅在编辑页提供（如「清除预约」）：PUT `0` + pending omit。
- 仅改备注/数量等 history 字段：允许不改预约；若实现顺带写回，MUST 原样写回已读 `nextAt`。

### D6：清空两步（仅编辑页触发）

1. `PUT appointment` `nextAt=0`
2. 重建 pending **omit** 该根 `eventId` 后同步

## Risks / Trade-offs

- **[Risk] 只写预约表忘更新 pending → 仍可能推旧时间** → 实现与验收清单强制两步。
- **[Risk] options 缓存旧无字段** → 缺省非预约；equality 含标志；后端重建缓存后刷新客户端目录。
- **[Risk] 过期仍推 → 用户可能收到「已过期」提醒** → 产品已接受；编辑页可清或改未来时间。
- **[Trade-off] MVP 预测卡/引导 sheet 不能清空** → 减少误触；取消约定走编辑页。

## Migration Plan

1. 制品已按需求确认更新（本步）。
2. 后端已部署后，客户端发版解析 `isAppointment` 并接线 API / UI。
3. 旧客户端忽略新字段，行为与今相同。

## Open Questions

- （无）需求确认已收口；实现期控件视觉细节可随现有 glass sheet 规范微调。
