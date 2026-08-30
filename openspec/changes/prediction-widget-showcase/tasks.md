## 1. 安装态与路由

- [x] 1.1 封装 `hasPinnedHomeWidget()`（`HomeWidget.getInstalledWidgets()`；失败/Web → false）
- [x] 1.2 go_router 注册展示页路由（如 `/widgets/showcase`）

## 2. 预测页入口

- [x] 2.1 竖屏 Stack 底部悬浮钮；横屏/Web 不展示；进页/resume 刷新安装态文案
- [x] 2.2 未钉「添加桌面小组件」/ 已钉「查看桌面小组件」；点击进入展示页
- [x] 2.3 预测列表底留白，避免被 FAB 遮挡
- [x] 2.4 未登录或未绑定：不展示 FAB，底留白跟 flag 收窄（`bound &&` 调用方门闸）

## 3. 展示页

- [x] 3.1 未钉：分平台添加说明；无刷新按钮
- [x] 3.2 已钉：能力说明；「刷新小组件数据」→ `ensureWidgetReadyFromRef` + 成功提示
- [x] 3.3 large Flutter 预览组件（同源 rows/visual；empty/loading）
- [x] 3.4 预览对齐桌面 large：事件 logo + hero/横向 recent 排版（非色条列表）

## 4. 验收

- [x] 4.1 竖屏两态文案与页内区块正确；横屏无 FAB
- [x] 4.2 已钉刷新后桌面数据更新；未钉无刷新入口
- [x] 4.3 未改 `app/android/**` 则跳过 release APK；禁止裸 print；新 Debug tag 须三联改
- [ ] 4.4 冒烟：未登录/未绑定竖屏无 FAB；已绑定竖屏有 FAB
