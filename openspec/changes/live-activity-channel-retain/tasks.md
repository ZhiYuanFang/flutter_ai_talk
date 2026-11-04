## 1. 强持有 Live Activity MethodChannel

- [x] 1.1 `PredictLiveActivityBridge.channel` 改为强引用（去掉 `weak`）；`AppDelegate` 创建 channel 后赋给 Bridge，避免仅局部 `let` 被 ARC 回收
- [x] 1.2 `deliver`：channel 为空只记 `no_channel`、不增加 `pushToStartDeliverCount`；成功 `invokeMethod` 后再计数

## 2. 诊断分类

- [x] 2.1 新增 `LiveActivityErrorCategory.nativeDeliverDartMiss`（短码 `native_deliver_dart_miss`）及人话
- [x] 2.2 `_applyTimeoutDiagnosis`：`ptsDeliver>0` 且本轮两类 unseen → 该类；`partial_attributes` 仅在至少一类 seen 或一类 ok 时使用
- [x] 2.3 锁屏设置页展示该类别文案与可复制摘要短码

## 3. 验收

- [x] 3.1 说明：修复后手动开通应能出现 `immSeen`/`timSeen`（或 HTTP 错），不再出现 `ptsDeliver>0 && seen=0` 被标成 partial
- [x] 3.2 `dart analyze` 相关 Dart 文件无新增问题
