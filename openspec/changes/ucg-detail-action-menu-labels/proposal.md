## Why

动态详情页时间行「··」展开的互动浮层目前仅展示图标，选项含义不够直观、可点区域也偏小。用户希望在每个操作图标右侧增加中文文案（点赞、评论、删除），提升可读性与点击体验。

## What Changes

- `UcgMomentsActionMenu` 展开 pill 中每项由「仅图标」改为「图标 + 文案」横向排列。
- 三项固定文案分别为：**点赞**、**评论**、**删除**（已赞态图标可变为实心，文案仍为「点赞」）。
- 非作者查看他人动态时 pill 仍只展示点赞与评论两项；作者额外展示删除项。
- 不改变浮层展开/收起行为、锚点位置与现有回调语义。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-interactions`：补充详情页时间行互动浮层 pill 必须展示图标与中文标签的要求。

## Impact

- **Flutter**：`app/lib/ucg/ui/widgets/ucg_feed_moments_widgets.dart`（`_ActionIcon`、`UcgMomentsActionMenu` overlay）。
- **范围**：当前 `UcgMomentsActionMenu` 仅用于 `UcgPostDetailScreen` 时间行，无 API/后端变更。
