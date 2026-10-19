## Why

满意度每一行的三个评价现在靠左排开，选中后都是同一种主题色，扫下来分不清哪一列是未使用、不好用还是好用。标题「满意度」又和选项列表绑在同一次滚动里，选项一多标题就滚出屏幕。

## What Changes

- 「满意度」标题钉在 sheet 顶部，不进入滚动。说明和选项行放在中间列表里滚动。更多意见、按钮上方的错误和提交按钮钉在列表下面。
- 每一行左文案、右评价。三个按钮始终贴右，不掉到文案下面另起一行。
- 「未使用」「不好用」「好用」各自有未选底色和选中实底，颜色经 `AppColor`。未选也能分开。
- 不改提交字段、拼接规则、必填规则和错误展示位置。不改 Go。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-satisfaction-survey`：sheet 的标题固定、列表滚动，以及三个评价的位置和区分样式。

## Impact

- **sheet**：`app/lib/ui/home_satisfaction_survey_sheet.dart`。弹出时关闭外层整页滚动，只让中间列表滚。
- **颜色**：若 `AppColor` 还没有评价所需的浅底/实底角色，只加薄封装，不写死色值。
- **不变**：`optionResults` 拼接、GET、主壳门闩、意见 1000 字和按钮上方错误。
