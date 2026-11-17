## 1. 共享常量与墙免费 logo

- [x] 1.1 增加 `kPredictFreeTierLogoAsset`（`assets/images/pre_basic.png`）供墙与 3h 共用
- [x] 1.2 两档墙免费卡顶部展示该 asset；Pro 仍网络 logo（有 URL 时）

## 2. 接下来3小时卡左侧 logo

- [x] 2.1 `_NextThreeHoursTimeline` 改为左 logo + 右 Column（标题行+正文），`CrossAxisAlignment.center`
- [x] 2.2 syncing/免费 → `pre_basic`；Pro → catalog logo；无 URL → 定尺寸占位（如 `FeatureLogo`）
- [x] 2.3 确认整卡开墙、`Icons.upgrade`、无 AI分析 行为不变

## 3. 校验

- [x] 3.1 `dart analyze` 相关文件无新增 error
- [ ] 3.2 手测：墙免费有图；3h syncing/免费/Pro（有无 URL）左侧正确且纵向居中
- [x] 3.3 Android 原生未改：**N/A** release APK / proguard
