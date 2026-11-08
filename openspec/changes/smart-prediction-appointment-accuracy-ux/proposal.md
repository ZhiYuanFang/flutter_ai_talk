## Why

智能预测页上，准确率图区手势不完整、预约根在竖列表被准确率示例图「占坑」、瀑布预约卡仍用「预测/预计」文案且 logo 放大、下次预约缺备注（需 Go twin）、一次性打点仍走确认框而非编辑态 sheet；另编辑 sheet 深色主题下主按钮字色与覆盖后的 primary 可能不配。需一次整包对齐产品，并与 Go `appointment-next-remark` **同发**（Go 先合备注契约，Flutter 跟读跟写，不做 UI 占位）。

## What Changes

- **准确率图区手势**：小结态整块图区（含明细行）单击 ≡ 返回箭头（回柱图）；柱图/小结图区 **显式** 长按触发与整卡相同的 list↔瀑布布局 toggle。
- **竖列表藏预约**：`isAppointment` 根在竖列表 **完全不渲染**（含无 nextAt）；「补充下次」与预约 countdown/改约 **仅** 瀑布（及既有横屏 compact 预约路径）。
- **预约卡展示**：文案「预测/预计」→「预约」；推演开启时 logo **保持标题行左侧**，不居中放大；「上一次」展示最新 history 时间 + 可选 ` · {remark}`（history 最新一条 remark）。
- **下次预约备注（依赖 Go）**：专用 sheet 可输入备注；GET/PUT `/device/app/api/appointment/next` 读写 `remark`；卡上预约时刻后可跟 ` · {下次备注}`；新增/改约默认填入 **上一次预约备注**（appointment 域，非 history）。
- **一次性 `eventType=one`**：预测卡叶子 `add` 由「确认添加」即时打点改为直接打开与编辑态同类的记录 sheet（可填时间/备注）。
- **主题**：实心保存/确认钮字色与实际 primary 成对（`AppColor.onPrimary` / 主题层同步 `onPrimary`）；去掉写死白/黑字。
- **非目标**：不改准确率计分公式；不改 Live Activity；不在无 Go 备注契约时用假字段糊 UI。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-list-accuracy-bars`：图区单击回柱图；图区长按切布局；竖列表不展示预约根（故预约不再出现准确率/示例柱）。
- `appointment-event-client`：竖列表隐藏；瀑布文案/logo/上次 history·remark；下次预约备注契约（对齐 Go）；改约默认上次预约备注。
- `event-record-sheet`：预测卡 `time|one` 普通新增由「确认添加」即时 now 改为直接打开统一记录 sheet。
- `theme-on-primary`：深色壳覆盖 `primary` 时同步 `onPrimary`；sheet 主钮跟 `AppColor.onPrimary`。

## Impact

- Flutter：`smart_prediction_screen.dart`、`appointment_next_sheet.dart`、`appointment_next_repository` / provider、`event_add_actions.dart`、`event_record_sheet.dart`、`home_history_edit_sheet.dart`、`app_theme_scope.dart` 等。
- 对端：Go `appointment-next-remark` **已落地**（GET/PUT `remark`，`max-length:512`，`nextAt=0` 清备注）；本仓跟读跟写，PUT **必须始终传** `remark` 字符串。
- 基线：相对 `openspec/specs/v2.1.8.md` 多处 BREAKING（竖列表预约可见性、确认添加、sheet 字段）。
