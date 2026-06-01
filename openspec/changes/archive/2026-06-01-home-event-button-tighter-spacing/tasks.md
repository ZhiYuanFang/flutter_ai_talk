## 1. 间距常量

- [x] 1.1 将 `kHomeEventButtonColumnGap` 从 8 调整为 4
- [x] 1.2 ~~将 `kHomeEventButtonColumnWidth` 从 72 调整为 64~~（按产品要求跳过，列宽保持 72）
- [x] 1.3 ~~将 `ListView` horizontal padding 从 8 调整为 6~~（按产品要求跳过，仅缩按钮间距）

## 2. 验证

- [x] 2.1 `flutter analyze lib/ui/home_button_event_grid.dart`
- [x] 2.2 手工：按钮模式底部，确认间距缩小、长名称仍 2 行省略、点击正常
