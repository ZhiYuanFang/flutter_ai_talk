## 1. 三小时卡热区与图标

- [x] 1.1 在 `_NextThreeHoursTimeline` 将开墙 `InkWell` 提升为整卡热区；去掉仅包后缀的内层 InkWell，避免嵌套抢点
- [x] 1.2 `onTap` 仅在非 syncing（`canOpenWall`）时调用 `showPredictCapabilityTierWall`，`initialTier` 仍对应当前后缀；Pro 与免费行为一致
- [x] 1.3 免费版后缀旁增加 `Icons.upgrade`（同色、紧挨文案）；Pro / syncing 不渲染该图标
- [x] 1.4 去掉依赖「仅后缀下划线」暗示可点的样式（可选保留粗体档位文案）；确认整卡仍不进喂养、无 AI分析

## 2. 校验与手测

- [x] 2.1 `dart analyze`（或 IDE 分析）确认 `smart_prediction_screen.dart` 无新增问题
- [ ] 2.2 手测：免费版点正文/标题开墙且见 upgrade 图标；Pro 版整卡开墙且无 upgrade；syncing 不可开墙；关墙正常
- [x] 2.3 Android 原生未改：本变更 **N/A** release APK / proguard（无需执行）
