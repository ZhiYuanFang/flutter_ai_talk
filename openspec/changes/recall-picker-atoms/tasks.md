## 1. 单滚轮原子

- [x] 1.1 新增玻璃单滚轮 Sheet API（标题、初始 index、labels、确认返回 index）；字色/高亮对齐用量轮
- [x] 1.2 量身定做 `_pickInterval` 改调该 API；移除系统白底间隔 popup

## 2. 时间原子

- [x] 2.1 量身定做 `_pickLastAt` 改用玻璃日期 + 时分 Sheet（或等价同族组合），结果 clamp ≤ now
- [x] 2.2 移除系统白底 `CupertinoDatePicker` popup

## 3. 校验

- [x] 3.1 `dart analyze` 触及文件无新增 error
- [x] 3.2 手工：量身定做打开间隔/时间均为玻璃单滚轮或玻璃日期时分；确认后卡片文案更新
