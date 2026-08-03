## 1. 抽壳（门禁：模式球）

- [x] 1.1 参数化 `edge_dock_geometry`（diameter）；兼容旧 `home_input_dock_geometry` 导出或薄包装
- [x] 1.2 实现 `EdgeDockShell`：peek/engaged/floating、半圆、热区外扩、slop、累计向内拉、pointer 占用回调
- [x] 1.3 `HomeInputModeDock` 改为壳消费者；保留 cycle/persist；行为零回归
- [ ] 1.4 手工：模式球贴边/拖动/点按切换/锁滑与改前一致

## 2. tip 迁壳（对齐效果）

- [x] 2.1 tip docked/collapsed 浮圆改挂 `EdgeDockShell`；删自建弱拉出/窄热区
- [x] 2.2 展开卡过半松手 → 壳 peek；点/累计拉出 → expanded；锁滑走壳回调
- [ ] 2.3 手工：tip 可贴四边、可点出、可慢速拉出、按球不切页；新 tip 仍强制居中展开

## 3. 收尾

- [x] 3.1 未改 `app/android/**` 则无需 release APK
