## 1. 壳基线

- [x] 1.1 删除 `externalPeekEngage` / peek 点按直达业务旁路；peek 点按仅 `_engage()`
- [x] 1.2 拉满阈值路径：engage 后若提供 `onPullBusiness`（或等价命名）则调用；点按永不走该回调
- [x] 1.3 确认 `onInteractiveTap` 仅在 engaged / floating 点按触发

## 2. 宿主接线

- [x] 2.1 tip：去掉旁路；`onInteractiveTap` + 拉满业务均指向展开；无半圆点击专用逻辑
- [x] 2.2 模式球：不传拉满业务；确认半圆点=engage、全圆点=cycle，零回归

## 3. 验收与收尾

- [ ] 3.1 手工：半圆点只全圆；tip 拉满可展开；全圆/浮空点展开 tip；按球锁滑
- [x] 3.2 未改 `app/android/**` 则无需 release APK
