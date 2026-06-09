# 详情页顶栏简介与正文折叠

## Why

详情页正文过长时占满首屏；作者简介在 ListView 内全文展示，与顶栏信息重复且浪费滚动空间。

## What

- 顶栏：昵称与 `authorBio` 同一 Column，与头像纵向居中；bio 小字单行 ellipsis。
- 正文：`post.text` 默认最多 5 行，超出显示「展开」；点击后全文展示，不提供「折叠」。
- 范围：仅 `UcgPostDetailScreen`；Feed 卡片不变。

## Impact

- `app/lib/ucg/ui/ucg_post_detail_screen.dart`
- MODIFIED `ucg-profile` / `ucg-interactions` delta specs
