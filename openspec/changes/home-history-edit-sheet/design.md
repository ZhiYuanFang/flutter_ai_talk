## Context

- 主页历史列表点击行当前调用 `context.push('/history/:id')`，进入 `HistoryDetailScreen`（预览/编辑双模式、Material 时间/日期选择器、AppBar 删除）。
- 添加事件已有 Bottom Sheet 先例：`home_number_event_sheet`（Cupertino 用量滚轮）、`event_catalog_picker_sheet`（固定 2/3 高度）、`home_reply_bottom_sheet`（内容自适应 + 局部 max）。
- 编辑/删除/校验逻辑已在 `HistoryDetailScreen` 与 `FeedRepository.updateHistoryRecord` / `deleteHistoryRecord` 中实现；`home_screen._stopActiveTimer` 已实现列表行停止计时。
- 用户已确认：**计时可在 Sheet 内停止**；**pending 只读**；**用量滚轮与添加一致**（5–500 步进）。

## Goals / Non-Goals

**Goals:**

- 点击历史行 → 主页底部 Sheet，直接进入可编辑态（无全屏预览页）。
- 时分：`CupertinoPicker` 滚轮；日期只读展示，取自记录 `startTime`/`endTime` 的日历日。
- 按 `eventNumber` 展示字段；保存/删除/停止与网关及 `homeHistoryProvider` 同步。
- 抽取共享 Bottom Sheet 布局：**maxHeight = 2/3 屏**，内容少时 **intrinsic**，多则内滚。
- 移除 `HistoryDetailScreen` 与 `/history/:recordId` 路由。

**Non-Goals:**

- 修改网关 update/delete 契约或 WS 协议。
- 在 Sheet 内修改事件名、事件类型或日期。
- 语音/文字路径的历史编辑。
- 为 pending 提供编辑/删除（仅只读展示）。

## Decisions

### 1. 入口与数据源

- `home_screen._openHistory(record)` 改为 `showHomeHistoryEditSheet(context, record: record, …)`。
- Sheet 打开时从 **`homeHistoryProvider` 按 id 取最新行**（避免 stale）；若 id 不在列表则 Toast 并关闭。
- **不**再调用 `getRecord` 单独拉详情（列表 + WS 对账已足够）；若未来需强一致可再增。

### 2. Sheet 结构与交互

```
AppAdaptiveBottomSheet
├── Drag handle（showDragHandle: true）
├── EventNameHeader（只读）
├── 只读日期行（yyyy-MM-dd，来自锚定 instant）
├── Cupertino 时分滚轮（1 或 2 组，按 eventNumber）
├── 用量滚轮（eventNumber > 1，复用 _numberPickerValues）
├── 备注 TextField
├── [停止]（仅 eventNumber==0 && 计时中 && 非 pending）
├── [保存] [删除]（pending 时隐藏或整页只读）
└── PopScope：dirty 时 dismiss 需确认
```

- **pending 只读**：检测 `isPendingHistoryId(id)` → 滚轮/输入禁用，隐藏保存/删除/停止，可选顶部文案「同步中…」。
- **停止**：复用 `_stopActiveTimer` 逻辑（update 写 `endTime=now`）→ `replaceRecord` → 关闭 Sheet；与列表行停止一致。

### 3. 时间滚轮实现

- 新建轻量 `HomeHistoryTimeWheel`（或内联）：两列 `CupertinoPicker`（0–23 时、0–59 分），或 `CupertinoDatePicker(mode: time)` 隐藏日期部分不可行 → 用双列 picker。
- 合成 `DateTime(anchor.year, anchor.month, anchor.day, h, m)`；**不得**暴露日期 picker。
- `eventNumber==0`：开始、结束各一组滚轮；结束可「清除」→ 提交 `endTime=0`。
- `eventNumber==1` / `>1`：仅结束时间一组滚轮；保存时 `startTime`/`endTime` 规则与现 `HistoryDetailScreen._save` 一致。

### 4. 保存与删除

- 校验逻辑从 `HistoryDetailScreen._save` 平移（结束早于开始、用量必填等）。
- 成功：`updateHistoryRecord` → `_history.replaceRecord` → Toast「已保存」→ `Navigator.pop`。
- 删除：AlertDialog 确认 → `deleteHistoryRecord` → `_history.removeRecord` → Toast「已删除」→ pop。
- **不再** `pop(true)` 触发 `_reloadHistoryIfLoggedIn()` 全量刷新。

### 5. 共享 Bottom Sheet 布局 `AppAdaptiveBottomSheet`

```dart
// 伪代码
ConstrainedBox(
  maxHeight: MediaQuery.sizeOf(context).height * 2 / 3,
  child: Padding(
    padding: EdgeInsets.only(bottom: viewInsets.bottom + viewPadding.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Flexible(
          child: SingleChildScrollView(
            child: body, // intrinsic 内容
          ),
        ),
      ],
    ),
  ),
)
```

- `showModalBottomSheet(isScrollControlled: true)` 包裹上述 widget。
- **迁移**：`event_catalog_picker_sheet` 去掉固定 `SizedBox(height: 2/3)`，改用 `Flexible`+列表；目录项多时在 2/3 内滚动。
- `home_number_event_sheet`、`home_reply_bottom_sheet` 套用同一 helper。

### 6. 路由与代码删除

- 删除 `app_router` `/history/:recordId` 与 `history_detail_screen.dart` import。
- 搜索并清理测试/README 中对 HistoryDetail 的引用。

### 7. 用量滚轮复用

- 从 `home_number_event_sheet.dart` 提取 `_numberPickerValues` 与 picker 高度常量到共享文件（如 `home_event_number_picker.dart`），添加与编辑共用，避免 drift。

## Risks / Trade-offs

- **[Risk] 键盘顶起备注导致 Sheet 超高** → `viewInsets` padding + 内层滚动 + max 2/3 约束。
- **[Risk] 目录 picker 改自适应后列表很短时 sheet 变矮** → 符合产品要求；长列表仍 max 2/3 内滚。
- **[Risk] pending 只读时用户困惑** → 只读态 + 「同步中」提示；对账完成后需关闭重开才能编辑（或 listen provider 自动切可编辑——**Non-Goal**，首版不自动切换）。
- **[Trade-off] 去掉 getRecord** → 极短窗口内 WS 未合并的字段可能略旧；可接受。

## Migration Plan

1. 新增 `AppAdaptiveBottomSheet` + `showHomeHistoryEditSheet`。
2. 切换 `_openHistory`；验证保存/删除/停止/pending。
3. 迁移其余 bottom sheets 高度规则。
4. 删除 HistoryDetail 与路由；更新 README。
5. 手工：跟底添加 → pending 只读；已落库记录编辑；计时中 Sheet 停止；目录 picker 高度。

## Open Questions

- （已决）计时停止在 Sheet 内提供。
- （已决）pending 只读。
- （已决）用量滚轮与添加一致。
