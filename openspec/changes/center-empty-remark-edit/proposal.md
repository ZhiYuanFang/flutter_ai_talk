## Why

统一记录 create / 历史编辑 sheet 的备注折叠行在备注为空时，「编辑备注」被左对齐（尾部 Spacer），视觉偏一侧。需要空态时将该入口横向居中，有备注时布局不变。

## What Changes

- 备注为空且折叠时：「编辑备注」+ 编辑图标 **必须** 在折叠行内横向居中。
- 备注非空时：仍为左备注正文 + 右「编辑备注」入口，**不得**改成居中整行。
- 不改展开输入、候选标签、占位文案规则（仍不得「暂无备注」）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-record-remark-sheet-ux`：空备注折叠行「编辑备注」横向居中。

## Impact

- Flutter：`app/lib/ui/widgets/event_remark_collapsed_row.dart`（create / 历史编辑 sheet 共用）。
- 无 API / 无 Android 原生；Release N/A。
