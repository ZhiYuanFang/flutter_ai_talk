## 1. 顶栏作者简介

- [x] 1.1 顶栏 Row `crossAxisAlignment: center`；昵称+bio 同一 Column（`mainAxisSize: min`），与头像纵向居中 — `ucg-profile`
- [x] 1.2 bio 小字单行 ellipsis；移除 ListView 内 bio 块 — `ucg-profile`

## 2. 正文五行展开

- [x] 2.1 `post.text` 默认 maxLines 5；`TextPainter` 判定超行时显示「展开」 — `ucg-interactions`
- [x] 2.2 点击「展开」后全文展示，不显示「折叠」 — `ucg-interactions`
