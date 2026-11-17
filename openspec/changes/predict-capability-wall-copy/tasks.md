## 1. Flutter 墙与 3h

- [x] 1.1 两档墙去掉右上 ✕；实现点遮罩/外部关闭（卡内不误关）
- [x] 1.2 Free 硬编码 Markdown 能力清单（行首 emoji；约定条目与小智措辞；禁亲和等算法词）；左对齐滚动渲染
- [x] 1.3 Pro 正文按 Markdown 渲染 catalog `description`；logo 与 Free 同框 `BoxFit.contain`
- [x] 1.4 底栏改为非按钮状态标签：Free 恒「正在使用」；Pro 已开通「正在使用」否则「敬请期待」；短路试用/支付 CTA
- [x] 1.5 3h 卡隐藏 `Icons.upgrade`；整卡开墙行为保持
- [x] 1.6 `dart analyze` 相关 Dart 文件无新增 error

## 2. Go description TEXT

- [x] 2.1 `go_ai_talk`：`feature_def` CREATE 将 `description` 改为 TEXT
- [x] 2.2 EnsureSchema 幂等 `MODIFY COLUMN description TEXT NOT NULL`
- [x] 2.3 确认 Admin/catalog 路径无 512 截断逻辑；必要时去掉

## 3. 墙抛光

- [x] 3.1 脚浅透底（非全透明）；logo 缩小为固定高度小图；去掉「能做什么」H2；列表无 · marker
- [x] 3.2 展示文案「免费版」→「基础版」（3h 后缀 + 墙标题）；spec 同步
- [x] 3.3 非可点脚：浅灰底 + 黑字（不再用 accent 填底/着色）
- [ ] 3.4 手测：点外关墙；基础版 MD；脚浅灰黑字；3h 无 upgrade；无「免费版」
- [x] 3.5 Android 原生未改：**N/A** release APK
