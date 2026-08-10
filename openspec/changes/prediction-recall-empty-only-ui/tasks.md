## 1. 触发门闸（策略 B）

- [x] 1.1 仅当 prediction range ready 且真历史 items 为空时允许启动量身定做会话；有任意记录则强制不展示并结束会话
- [x] 1.2 空库时仍按全部未关推演根建队；核对「有历史不进引导」手工路径

## 2. PageView UI 与 chrome

- [x] 2.1 将引导改为悬浮卡 PageView + `NeverScrollableScrollPhysics`；确认/跳过/继续仅程序切页
- [x] 2.2 `showRecallOnboarding` 时隐藏值得留意、接下来 3 小时、底部 tip；CTA 后恢复原逻辑

## 3. 验收

- [x] 3.1 手工：空库引导、有历史不引导、禁手滑、chrome 隐藏、种子/跳过/CTA 仍可用
- [x] 3.2 未改 Android 原生则跳过 release 构建
