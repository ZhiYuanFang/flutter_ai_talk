## 1. 模型与墙布局

- [x] 1.1 定义基础版能力条目模型（emoji/title/subtitle/kind）与 8 条常量数据
- [x] 1.2 基础版墙正文改为条目列表（文案上、demo 下）；移除整段 Free Markdown 渲染
- [x] 1.3 Pro 档保持 catalog Markdown 路径不变

## 2. 中档 demo 控件

- [x] 2.1 实现 8 个 demo：nextEstimate / pushRemind / homeWidget / familyShare / landscapeCast / voiceBall / trendChart / xiaozhiSpeaker（假数据、IgnorePointer）
- [x] 2.2 抽到独立 widget 文件；跟墙玻璃/档位色协调
- [x] 2.3 `dart analyze` 相关文件无新增 error

## 3. 校验

- [ ] 3.1 手测：基础版 8 条均有 demo；点 demo 无业务副作用；Pro 仍 MD；滚动正常
- [x] 3.2 Android 原生未改：**N/A** release APK
