## 1. `_ActionIcon` 带标签布局

- [x] 1.1 为 `_ActionIcon` 增加必填 `label` 参数，内部改为 `Row(Icon, SizedBox(width:4), Text)` 横向布局（`ucg-interactions` / Detail time-row action menu pill SHALL show icon with Chinese labels）
- [x] 1.2 文案样式：`fontSize: 13`、`fontWeight: w500`，颜色与图标 `color` 一致；项内 padding 使用 `horizontal: 8, vertical: 6`（或沿用开发者已调整的尺寸）

## 2. 浮层 pill 调用与外观

- [x] 2.1 在 `UcgMomentsActionMenu._buildOverlayEntry` 三处 `_ActionIcon` 分别传入 `label: '点赞'`、`'评论'`、`'删除'`（`ucg-interactions`）
- [x] 2.2 可选：pill 外层 `Padding` horizontal 4→6、`borderRadius` 6→8，避免标签贴边

## 3. 验证

- [x] 3.1 详情页：非作者展开菜单仅见「点赞」「评论」两项带标签；作者见三项含「删除」（`ucg-interactions` / 非作者展开菜单见点赞与评论标签、作者展开菜单见三项标签）
- [x] 3.2 点击任一带标签项：浮层收起且触发点赞/评论 sheet/删除确认，行为与改前一致（`ucg-interactions` / 点击带标签的操作项）
