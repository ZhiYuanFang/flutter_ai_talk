## 1. 叶子身份

- [x] 1.1 计时中用 `lookupEventForRecord` 解析叶子；标题名/logo/accent（elapsed+停止）跟叶子；不可解析时安全回退

## 2. 停止心跳

- [x] 2.1 「停止」可点时持续 scale 心跳（对齐 `_HeartbeatLogo` 节奏）；`_stopping` 时停动画并显示忙碌态

## 3. 验收

- [x] 3.1 手工：叶子计时时卡显示叶子名/图/色；停止心跳；点停止后恢复根倒计时 chrome；列表态不变
