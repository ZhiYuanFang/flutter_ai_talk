## Context

`predict-expect-amount-duration` 已在客户端实现：根下 duration/amount 双线、胜出挂到 `EventNextPrediction`、卡上次级「预计约…」、pending 结构化字段。  
目录 `eventType=one` 落库固定 `eventNumber=1`，当前 amount 线仅看 `eventNumber>0`，把一次性发生误当成计量。  
卡片 UI 把 `expectLabel` 放在标题区（`lastOccurrence` 之后），竖屏大 logo 与倒计时在更下方，阅读顺序是「预计 → logo → 倒计时」。

## Goals / Non-Goals

**Goals:**

- 样本与决胜模态按目录叶子 `eventType` 排除 `one`，使 one 不产生任何 expect。
- 有倒计时展示时，「预计约…」紧贴倒计时上方；有大 logo 时位于 logo 与倒计时之间。
- pending / 指纹随无 expect 自然正确（少传假 amount）。

**Non-Goals:**

- 不改 `nextAt` 间隔算法、不改预约、不改进行中 ETA 文案位置。
- 不改 Go 契约；不做 expect recall；不改横屏省略叶子名规则本身。
- 不为缺 `eventType` 的旧缓存叶子发明新启发式（见 Risks）。

## Decisions

### D1：按叶子 `eventType` 过滤，而非根级一刀切

- **选择**：收集 duration/amount 点与 `countableExpectKind` 时，用记录 `eventId` 查目录；`parsedEventType == one` 则跳过。喂养根下 number/time 叶子不受影响。
- **备选**：仅根 `eventType==one` 时跳过整卡 attachExpect → 根缺 type 或混叶子时仍可能误算。
- **备选**：`eventNumber==1` 且无 unit 启发式 → 误伤「每次 1 片」等真计量。

### D2：API 入参带 catalog（或 id→type 映射）

- `resolveWinningExpect` / `attachWinningExpect` / `_durationSamplePoints` 等路径需能解析叶子类型；与 `predictAllUpcoming` 已有 catalog 入参对齐，避免再扫全局 provider。
- 目录查不到或 `eventType` 非法/缺失：该条**不**按 one 排除（保持与「未知 type 不进加按钮」正交）；若误为 number 仍可能进 amount——见风险。

### D3：布局——expect 并入倒计时区块

- 从标题 Column 移除 `expectLabel` 块。
- 竖屏 compact 且 `showHeroLogo`：顺序为 logo →（可选 gap）→ expect（若有）→ 倒计时。
- 无大 logo 但仍渲染倒计时（如后列 `titleInlineLogo`）：expect 仍紧贴该倒计时上方。
- 无倒计时区块时（关推演 / 无 pred / 计时中）：不强制展示 expect（与既有「计时中不展示 expect」一致）。

### D4：与兄弟 change 关系

- 行为上修正 `predict-expect-amount-duration`；规格 delta 写在本 change，归档时可与前者一并合入基线。

## Risks / Trade-offs

- [旧缓存叶子缺 eventType] → 无法识别 one，仍可能「预计约1」；依赖目录刷新后纠正（与加事件门闸同类假设）。
- [根下误标 one 的计量叶子] → 被排除属目录数据问题，不在客户端兜底。
- [双 change 并行归档] → 合并基线时注意 requirement 全文以本 change 的 MODIFIED 为准叠在前者 ADDED 上。

## Migration Plan

- 纯客户端热更：重算预测后 one 卡 expect 消失，pending 指纹变化会再 PUT（受既有熔断约束）。
- 回滚：恢复样本不过滤 one、恢复标题区 expect 位置即可。

## Open Questions

- （无阻塞）横屏非 compact 图表卡是否也要在 countdown 旁挂 expect：本设计仅约束「存在倒计时文案区块」的路径；图表卡若无 countdown 行则不强制。
