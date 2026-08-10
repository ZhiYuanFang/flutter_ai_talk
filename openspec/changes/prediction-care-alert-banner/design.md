## Context

智能预测页已具备 tip 卡、7 日 range 历史与按 `nextAt` 排序的事件列表。预警需要在 tip 与列表之间插入一条轻量「值得留意」信号，数据复用既有 range store 与月龄助手，算法独立于 `event_next_predictor`（推演仍只负责 nextAt）。

## Goals / Non-Goals

**Goals:**

- 本地评估全事件，输出最多 1 条最高优先级预警；无则隐藏槽位。
- 双基准：自身 7 日基线 + 月龄期望表；未知月龄仅用自身基线。
- 类型优先级：间隔拉长 > 进行中过久 > 突然消失。
- Banner 可点进详情页，结构化展示原因。
- 语气「值得留意」，避免医疗诊断口吻。

**Non-Goals:**

- 不改推演公式 / tip SSE / 小组件同步契约。
- 不做多条预警列表、推送通知、服务端规则。
- 不做医学级完备期望库；首版粗分档可后续替换。
- 不自动新建 `test/` 文件。

## Decisions

### D1：独立模块 `prediction_care_alert`

- **选择**：`app/lib/data/prediction_care_alert.dart`（纯函数评估）+ provider 只读聚合；UI Banner / 详情页分离。
- **备选**：塞进 `event_next_predictor` — 拒绝，职责混淆且难测。
- **理由**：预警与 nextAt 推演阈值、样本定义不同，应可独立演进。

### D2：输入数据

- 历史：`predictionRangeHistoryProvider` 已 ensure 的 7 日 records（与图表同源）。
- 月龄：`BabyProfile.birthDate` + `babyAgeInMonths` / `isUsableBabyBirthDate`。
- 事件集合：与预测列表同源的可识别 `eventId`（catalog + 窗口内出现过的事件）；推演开关 OFF **不排除**预警扫描（留意独立于是否展示折线）。

### D3：双基准与触发语义

对每个事件计算候选（过阈值才入池）：

| 类型 | 自身 7 日基线 | 月龄期望表 | 触发条件（AND/OR） |
|------|---------------|------------|-------------------|
| 间隔拉长 | 相邻 occurrence 间隔中位数 `medianGap`；最近间隔 `lastGap` | 该月龄档期望间隔上限 `expectGapMax` | `lastGap ≥ max(medianGap × 1.5, medianGap + 2h)` **或**（有期望时）`lastGap ≥ expectGapMax`；且样本数 ≥ 3 |
| 进行中过久 | 近 7 日已结束 timing 时长的 P75 `p75Dur` | 单次上限 `expectDurMax` | 当前 active；`elapsed ≥ max(p75Dur × 1.5, expectDurMax?)`；无历史时长时仅比 `expectDurMax`（若有） |
| 突然消失 | 7 日日均 occurrence ≥ 0.5 | 该月龄仍「期望出现」 | 近 48h occurrence 数为 0；且期望表未标「可不出现」 |

未知月龄：忽略期望列，仅自身基线；期望相关字段在详情标「未使用」。

### D4：Top1 选取

1. 收集全部过阈值候选。  
2. 按类型优先级过滤：有间隔拉长则丢弃其余类型；否则有进行中过久则丢弃突然消失。  
3. 同类型取偏离分数最高（如 `lastGap / medianGap`、`elapsed / p75Dur`、或消失用日均×权重）。  
4. 无候选 → `null`。

### D5：UI 与路由

- Banner：玻璃拟化轻条，前缀「值得留意」，一句摘要（事件名 + 类型短句）。
- 位置：tip 卡下方、事件 `ListView` 上方（tip 缺失时仍可单独出现在标题下）。
- 路由：`/prediction/alert`，query 或 extra 传入结构化 `CareAlertReason`（或 eventId + 重新评估）；优先 **extra 传完整 reason**，避免详情页二次猜。
- 详情：展示类型、自身基线数字、月龄期望、实际观测、一句非诊断说明。

### D6：月龄期望表首版

本地 const 表，按月龄档 `0–3 / 4–6 / 7–12 / 12+` 与粗 `eventType`（或常见 eventId 别名）给出 `expectGapMax` / `expectDurMax` / `stillExpected`。未匹配类型 → 无期望约束（仅自身基线）。表可后续替换为远程配置，首版不拉网。

### D7：副作用与日志

- 评估为纯本地计算；**不得** 因 Banner 评估发起新 HTTP。
- 若需 debug，走 `AppDebugLog` 既有或扩展 tag（三联改）；默认可不打高频日志。

## Risks / Trade-offs

- [误报惊吓] → 语气「值得留意」+ 高阈值 + 最多 1 条；详情强调「相对自身近期」非诊断。
- [样本不足乱报] → 间隔拉长最少 3 次；消失要求日均门槛。
- [期望表不准] → 未知/未匹配不强制期望；可只靠自身基线。
- [与推演结果不一致] → 文案不声称「下次时间错了」，只谈间隔/时长/消失模式。

## Migration Plan

- 纯客户端增量；无数据迁移。
- 回滚：隐藏 Banner 路由与评估 provider 即可。

## Open Questions

- 首版期望表具体数值是否需产品/医学顾问微调（实现可用合理占位常量）。
- 详情页是否允许从深链直接打开（首版可不支持，仅 push from Banner）。
