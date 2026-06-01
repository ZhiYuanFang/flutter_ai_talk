## Context

- **现状**：`HomeScreen` 在按钮路径通过 `_submitEventAdd` 乐观写入 + `addHistoryEvent`；语音/文字经 `sendCommand` 后由 WS `upsertRecord` 落库。进行中判定见 `isActiveTimingRecord`（`active-timing-stop`）。同 `eventId` 的 time 按钮在新增前 Toast 拒绝；不同 eventId 可并行计时，无事后提醒。
- **既有 UI**：历史编辑 Sheet 已落地玻璃拟态（`HistoryEditGlassPanel`、`historyEditGlassTextColor`、pill 底栏取消/保存），用户要求本提醒对话框**视觉对齐该风格**，但交互为**屏幕居中**模态（非 bottom sheet）。
- **停止能力**：`_stopActiveTimer` 已封装 `updateHistoryRecord` + 本地 `replaceRecord`；列表/详情「停止」仍无二次确认。

## Goals / Non-Goals

**Goals:**

- 新增成功后在适当时机检测「除刚新增记录外」的其它进行中计时；有则弹出居中玻璃风对话框。
- 对话框内**可见具体事件**：名称、事件色/图标（若有 catalog 映射）、实时已计时长（`MM:SS` / `HH:MM:SS`）。
- **多条**时支持**多选**，主操作「结束所选」仅 stop 勾选记录；**单条**时默认选中，可简化为无勾选 UI。
- 「暂不」/关闭：不 stop，不阻断已完成的新增。
- 覆盖三条路径：事件按钮、语音、文字；避免按钮 optimistic 与 WS 重复弹窗。
- 对话框打开期间每秒刷新列表中的已计时长。

**Non-Goals:**

- 修改新增前同 eventId Toast 逻辑。
- 修改列表/详情行内「停止」的无确认行为。
- 「今日不再提醒」、推送通知、后台计时提醒。
- 将 bottom sheet 编辑 Sheet 本身改为居中对话框。

## Decisions

### 1. 呈现：居中 Dialog + 玻璃 Panel

```text
showDialog(
  barrierColor: Colors.black54,
  barrierDismissible: true,
)
  └ Center
       └ ConstrainedBox(maxWidth: ~340, maxHeight: ~0.55 * screen)
            └ HistoryEditGlassPanel(onClose: dismiss)
                 ├ 标题：「还有计时未结束」
                 ├ 说明：简短提示防遗忘
                 ├ ListView：每条进行中记录一行
                 ├ 底栏 Row：TextButton「暂不」| FilledButton pill「结束所选」
                 └ （可选）全选/取消全选（仅 count > 1）
```

- **为何居中 Dialog 而非 BottomSheet**：用户明确要求「中间弹窗」；玻璃视觉复用 `HistoryEditGlassPanel` 与编辑 Sheet 同色 token，保证与底部 Sheet **风格一致、位置不同**。
- **宽度**：水平 margin 24，最大宽约 340，与编辑 Sheet 内边距量级一致。

### 2. 列表行内容与多选

每条 `ActiveTimingReminderRow`：

| 元素 | 说明 |
|------|------|
| Checkbox | 仅当 `candidates.length > 1` 显示；默认**全选** |
| 事件名 | `record.eventName`，`titleMedium` + glass 前景色 |
| 已计时长 | `formatActiveTimingElapsed`（与 `active-timing-stop` 一致），`tabularFigures`，每秒 tick |
| 事件 accent | `lookupEventForRecord` + `resolveEventColor`，用于左侧色点或图标 |

- **单条**：隐藏 Checkbox，视为已选；主按钮文案可为「结束计时」。
- **多条**：至少勾选一条时「结束所选」可点；未勾选时 disabled。
- **pending**（`isPendingHistoryId`）：**不纳入**候选列表（无法 stop）。

### 3. 触发时机与去重

统一入口：`_scheduleActiveTimingReminderAfterAdd({required String excludeRecordId})`

| 路径 | 触发点 |
|------|--------|
| 按钮 | `_submitEventAdd` 在 `serverId != null` 且 `replaceRecordId` 之后；若 fly 动画进行中则 defer 至 `_onFlyOverlayComplete`（同 session），否则 post-frame 立即检查 |
| 语音/文字 | WS listener：`isNew == true` 且非 `_shouldScheduleWsFly` 导致的重复 upsert 时，`excludeRecordId = r.id` |

**去重**：

- 同一次新增仅弹一次：`_reminderSessionId` 或「对话框已打开则 queue 忽略」。
- 按钮路径：`serverId` 已在 `_recentlyReplacedIds`，WS upsert 不再单独触发 fly；提醒仅在 `_submitEventAdd` 成功链触发一次。
- 若用户关闭对话框后再次新增，可再次提醒（符合防遗忘）。

### 4. 停止执行

- 用户确认后，对选中 id **顺序**调用 `_stopActiveTimer`（或抽 `stopActiveTimers(List<HistoryRecord>)` 批量封装）。
- 部分失败：已成功项 UI 更新；失败项 Toast + 对话框内该行保留或标记错误；不 rollback 已成功 stop。
- 全部成功后 `Navigator.pop`；若 stop 后已无其它进行中，无需再弹。

### 5. 文件组织

- `home_active_timing_reminder_dialog.dart`：`showHomeActiveTimingReminderDialog(...)` + Stateful 列表 tick。
- `HomeScreen` 保留检测与调度；dialog 接收 `List<HistoryRecord> candidates`、`Future<bool> Function(HistoryRecord) onStop`。
- 可复用 `HistoryEditGlassPanel`；不强制新建 glass 子类。

### 6. 与 active-timing-stop 的边界

| 场景 | 行为 |
|------|------|
| 列表行点「停止」 | 仍直接 stop，无对话框 |
| 新增成功后提醒 | 本变更对话框，可选部分 stop |
| 编辑 Sheet 内停止 | 仍直接 stop（既有） |

## Risks / Trade-offs

- **[Risk] 连续快速新增多条** → 对话框打开时忽略新调度，或关闭后再弹；首版采用「已打开则跳过」。
- **[Risk] fly 动画与弹窗叠层** → defer 至 fly 完成；`disableAnimations` 时立即弹。
- **[Risk] 对话框 tick + 列表 tick 双 Timer** → 对话框内独立 `Timer.periodic(1s)`，仅 dialog mounted 时运行。
- **[Trade-off] 全选默认** → 防遗忘偏「结束」；用户需主动取消勾选以保留部分计时。

## Migration Plan

- 纯客户端功能；无数据迁移。手工验证：按钮 one/time/number、语音/文字新增、0/1/N 条其它计时、部分 stop、暂不、pending 不出现、深浅色 shell。

## Open Questions

- （默认）多条时不单独做「结束全部」第三按钮，「结束所选」+ 默认全选已覆盖。
- （默认）语音/文字若 WS 延迟 >3s 仍无 record，不弹窗（仅在有 excludeRecordId 的 upsert 时触发）。
