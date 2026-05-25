## 1. 玻璃容器与 Sheet 入口

- [x] 1.1 新增 `HistoryEditGlassPanel`（BackdropFilter + 渐变 + 描边 + 圆角）
- [x] 1.2 `showHomeHistoryEditSheet`：透明 modal、无 drag handle、内包 glass panel

## 2. 头部与关闭

- [x] 2.1 居中 Logo + 事件名；右上关闭按钮接 `PopScope` dismiss

## 3. 表单视觉

- [x] 3.1 `HomeHistoryTimeField` 玻璃条样式（大号 HH:mm + 铅笔图标）
- [x] 3.2 移除独立日期行；备注/用量区样式与玻璃风协调
- [x] 3.3 底栏：取消（左）+ 保存 pill（右）；删除/停止次级样式

## 4. 验证

- [x] 4.1 `flutter analyze` 相关文件
- [x] 4.2 手工：eventNumber 0/1/>1、pending、停止、删除、深浅色、关闭与脏检查
