## Context

现状：`showHomeNumberEventSheet`（仅今天时分）与 `showHomeHistoryEditSheet`（跨日 DateTimeRow + 媒体/删/广场）两套主壳；预测「补充上一次」= `handleEventGridTap` now 路径。基线 `home-history-edit-sheet` / `home-number-event-glass-sheet` 约束并排日期时间格与 number 新建能力；未归档 `prediction-catalog-complete-cards` 将补齐等同加事件。

约束：玻璃壳与 `HistoryEditGlassPanel` 色；弹层内 TextEditingController 由 Sheet State 持有；不新建测试；无 Android 原生改动。

## Goals / Non-Goals

**Goals:**

- 单一主业务入口 `showEventRecordSheet(intent, event [, record])`。
- intent×type 行为矩阵（见下）与操作类型标题。
- 居中分段时间行：`日·时` / `起 ~ 止` / `起 ~ 进行中`；子弹窗复用既有日期/时分 Sheet。
- 补充与无 lastAt 点卡对齐；预测普通新增非量保留「确认添加」。

**Non-Goals:**

- 喂养格 / 普通 add 的 time/one 开 Sheet。
- 「清除结束时间」/长按清除（本期不做）。
- 统一事件目录 picker、间隔回忆 Sheet、语音录入。
- 改服务端历史 API 契约。

## Decisions

### D1：Intent 枚举，而非布尔堆叠

`EventRecordIntent { supplement, add, edit }` 驱动标题前缀与字段默认值。预测无 `lastAt` 传 `supplement`；喂养格与有 lastAt 点卡传 `add`；历史行 /「上一次」传 `edit`。

**备选**：仅 `isSupplement` + 独立编辑 Sheet → 否决（与「一个主 Sheet」冲突）。

### D2：行为矩阵

| intent | type | UI |
|--------|------|-----|
| supplement | one | Sheet：发生时刻（跨日）；标题=事件名 |
| supplement | time | Sheet：开始 + 可选结束（空=进行中）；标题=事件名 |
| supplement | number | Sheet：发生时刻 + 用量；标题=事件名 |
| add | one / time | **无** Sheet；now（time 的 end=0）；预测直点叶子先「确认添加」 |
| add | number | Sheet：跨日时刻 + 用量；标题=事件名 |
| edit | * | 统一 Sheet：回填记录；标题=事件名；媒体/删/广场仅 edit |

打开 supplement / add·number 初值：**今日·当下**。edit 从记录回填。点「进行中」设结束时，选择器默认亦今日·当下。

### D3：一个主壳 + section，不是上帝 if

- `EventRecordSheet`：logo、事件名标题（无操作前缀）、时间 section、用量、备注、主按钮；edit 底部挂媒体/删/广场。
- 旧 `showHomeNumberEventSheet` / `showHomeHistoryEditSheet` 改为调用统一入口或删除并改调用点。
- 日期/时分仍为独立轻量 Sheet（非第三套业务表单）。

### D4：时间行原子

替换 `HomeHistoryDateTimeRow` 在记录 Sheet 中的用法：

```
        [今日]·[16:24]                 // 日小号字，时大号字；整行 Wrap/Row 居中
   [今日]·[16:24] ~ [今日]·[18:23]
   [今日]·[16:24] ~ [进行中]           // 点「进行中」→ 时分（可先定日）写入 end
```

- 日文案：`formatHistoryDaySectionLabel`（或「今日」与列表一致的映射）。
- 无「开始时间/结束时间」标签；无清除结束按钮。
- 仍保留 edit 时开始日/时相对结束的对齐规则（基线 `eventNumber==0`）。
- **着色**：传入事件 `accent`；时刻 / 标题用 `Color.lerp(accent, black, ~0.32)` 加深；日 / `·` / `~` 用同色系更淡（略深 + alpha）。

### D5：预测确认框与补充分流

`confirmDirectLeafBeforeAdd` **仅**在 `intent==add` 且 type∈{time,one} 时生效。`intent==supplement` 直接开 Sheet。`number` 永不弹该确认框。

### D6：提交

继续 `submitEventAdd` / 既有 edit save；time 无结束 → `endTime` epoch 0；one/number 起止同瞬时。

## Risks / Trade-offs

- [编辑 Sheet 体量大] → 先迁时间 UI + 标题 + 入口，媒体块原样挂 edit section，避免一次重写 700 行逻辑出错。
- [用户无法清回进行中] → 接受；规格写明删或改结束。
- [与未归档 catalog-complete 冲突] → 本 change 的 `smart-prediction-page` delta 显式改写「补充=now 加事件」。
- [日文案「今天」vs「今日」] → 实现统一用列表既有 `formatHistoryDaySectionLabel`；UI 稿「今日」若不一致，以既有函数为准并在 tasks 核对。

## Migration Plan

1. 落地时间行原子 → 编辑 Sheet 先换肤验证。
2. 统一入口 + number/supplement → 改 `event_add_actions` / 预测。
3. 编辑调用点切统一入口；删除重复主壳。
4. 手工验收矩阵；不改 release 原生。

## Open Questions

无（清除结束、初值、确认框、组件个数均已在 explore 锁定）。
