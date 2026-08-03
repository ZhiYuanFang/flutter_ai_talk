## 1. 占位基线

- [x] 1.1 geometry：圆心重叠判据与 along/浮空外推辅助
- [x] 1.2 实现 `EdgeDockOccupancy`（register/unregister/resolve + sticky）
- [x] 1.3 `EdgeDockShell` 松手路径走 resolve；暴露 occupancyId / sticky

## 2. 宿主接入

- [x] 2.1 模式球：sticky 注册；placement 变更同步
- [x] 2.2 tip 球：非 sticky 注册；无 tip/dismiss 时注销

## 3. 验收与收尾

- [ ] 3.1 手工：两球拖同边/同点不重叠；模式球不被 tip 挤走
- [x] 3.2 未改 `app/android/**` 则无需 release APK
