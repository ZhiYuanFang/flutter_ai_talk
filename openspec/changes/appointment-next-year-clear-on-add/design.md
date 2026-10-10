## Context

预约 nextAt 经独立 API 与 history 解耦；专用 sheet 在「补充下次」、编辑页改约、新增/补充后引导等路径复用。基线已写「年月日时分」，实现为 `CupertinoDatePickerMode.dateAndTime`（无独立年列）。Post-write 仅空/过期弹 sheet。预测卡整卡 InkWell 走加喂养；countdown 不可点；横屏 `!compact` 走折线图、无大倒计时。

已确认：年份在标题下可点、主区四列月日时分（年用独立 glass 单列）；**仅新增**清空；清空失败不弹；countdown 点按改约；**横屏同样**展示并可点。

## Goals / Non-Goals

**Goals:**

- Sheet：标题下展示当前年并可点选；主区月/日/时/分四列；年范围约 `2000 … now+5y`；确认 PUT 正 nextAt。
- 新增成功 → clear(0) → 成功才弹 sheet；失败 toast 且不弹。
- 补充成功：仍仅空/过期弹，不清空。
- 预约热态 + 有 pred：竖屏与横屏均展示 countdown 块；点按打开改约 sheet（带当前 initialNextAt）；不触发 add。
- 整卡非 countdown 区域仍可 add（关推演/既有规则不变）。

**Non-Goals:**

- 改服务端预约表结构或 pending 协议。
- 补充路径强制清空。
- 专用 sheet 提供「清空」（清空仍仅编辑 history 页）。
- 非预约卡 countdown 行为变更。

## Decisions

### 1. 可点年份 + 四列滚轮

- 标题下方一行展示 `YYYY年 ▾`；点按打开 `showGlassSingleWheelPickerSheet` 选年。
- 主区用 `CupertinoPicker` 拼月/日/时/分四列；日列随年月/闰年收束。
- 弃用该 sheet 内的 `CupertinoDatePicker.dateAndTime` 与五列同行年轮。
- 默认值：未来约定用 initial；否则 `now+7d`（保持现状）。

### 2. 新增后清空再引导

```
add 成功且 eventIsAppointment
  → clearAppointmentNextAt (PUT 0)
  → 失败：toast，return（不弹）
  → 成功：showAppointmentNextSheetAndSave（无 initial 或按 0）
```

- 触发面：`handleEventGridTap` / `event_add_actions` 在 **intent=add** 且预约根时走上述；`EventRecordIntent.supplement` 仍调用现有 `maybePrompt…`（空/过期）。
- 预测卡「补充下次」、编辑页改约、countdown 改约：**不得**先清空。

### 3. Countdown 点按改约（竖+横）

- 复用 `_onSupplementAppointment`（ensure + sheet + save）。
- 可点区域：caption「距离下次…倒计时」+ HMS 数字（含逾期样式）；内层手势吸收，避免冒泡到整卡 InkWell。
- **横屏**：预约根且 `pred != null` 时 MUST 渲染与竖屏同结构的 countdown 块（可置于图上方或替代「仅图」主英雄区）；点按行为相同。非预约横屏可保持仅图。
- 无 pred 时仍用「补充下次」CTA（既有）。

### 4. 失败与忙态

- clear / PUT 失败：既有 toast；busy 防重入（`_appointmentBusy`）。
- 清空失败不弹：避免本地以为空、服务端仍为未来 nextAt。

## Risks / Trade-offs

- [用户关掉 sheet 后 nextAt 已为 0] → 预期：卡变「补充下次」、pending omit；可接受。
- [二层 sheet 选年] → 与仓库 glass 单列一致；关闭年轮不丢主 sheet 状态。
- [横屏预约卡同时有图+countdown 更高] → 优先保证 countdown 可点；图可缩短或置于下方。

## Migration Plan

- 无数据迁移；纯客户端行为。
- 回滚：恢复 dateAndTime + 旧 post-write 条件即可。

## Open Questions

- 无（explore 已确认：B、仅新增清空、失败不弹、countdown 改约、横屏一致）。
