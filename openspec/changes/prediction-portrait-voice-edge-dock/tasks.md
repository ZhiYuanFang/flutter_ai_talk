## 1. 存储与宿主

- [x] 1.1 将 `HomeInputDockStore` 语义改为预测竖屏语音球：bump prefs key（或忽略旧 `home_input_dock_v1_*`）；默认 `DockEdge.left` + 偏下 along；可选 rename
- [x] 1.2 新增竖屏语音球宿主（包 `EdgeDockShell`）：圆形 mic+连接点、`onInteractiveTap`→`onListenChipTap`、无 channel 轮转、无 `onPullBusiness`

## 2. 预测页接入

- [x] 2.1 竖屏 Stack：用宿主替换固定 `Positioned` 胶囊；bounds 扣 SafeArea/底栏；字幕 toast 改为独立底中（不跟球）
- [x] 2.2 engaged/floating 时球旁或球下短显 `statusCaption`；peek 省略文案；横屏固定 chip 不动

## 3. 收敛与校验

- [x] 3.1 确认喂养页仍不挂 `HomeInputModeDock`；删除或废弃无用切模式 dock 代码路径（若仍被引用则切断）
- [x] 3.2 `dart analyze` 触及文件无新增 error
- [x] 3.3 手工：竖屏拖贴边、peek 点按只展开、全圆点按进听、默认左下、冷启恢复、字幕独立、横屏 chip 仍固定
- [x] 3.4 未改 `app/android/**` 则跳过 release；若触及原生再补 `flutter build apk --release` 与 proguard
- [x] 3.5 竖屏语音球壳热区按下/拖动期间 MUST 经 `onPointerOccupied` → `homePagerScrollBlockedProvider` 禁止主页 PageView 横滑
- [x] 3.6 修复 `EdgeDockShell`：engaged/拉满后拖动松手 MUST 仍走 `_finishDrag` 吸附落位，不得弹回原 edge/along
