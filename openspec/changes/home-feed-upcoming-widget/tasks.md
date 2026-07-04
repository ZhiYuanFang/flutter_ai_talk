## 1. Dart 预测与文案基础

- [x] 1.1 新增 `baby_age.dart`：`babyAgeInMonths`、`formatWidgetHeaderLine`（昵称截断、0 月/岁文案）
- [x] 1.2 新增 `event_next_predictor.dart`：分 6 时段桶、15min 过滤、加权中位数、月龄半衰期、`nextAt`/overdue
- [x] 1.3 新增 `widget_row_builder.dart`：active 优先 + 全局 nextAt 排序 + small/medium/large 行数预算
- [x] 1.4 新增 `format_widget_relative_time.dart`：overdue/upcoming/elapsed 单位规则（供 App 预览与 native 文档对齐）

## 2. 历史深度预拉与副作用治理

- [x] 2.1 新增 `widget_history_depth.dart`：`ensureWidgetHistoryDepth` single-flight、30 天/15 页/hasMore 停止、30s 超时
- [x] 2.2 扩展 `home_history_notifier`：预拉与 `loadMoreHistory` 共用 in-flight；连续 3 页失败熔断
- [x] 2.3 SharedPreferences：`widgetHistoryDepthReady` 读写；登出/清缓存时重置
- [x] 2.4 预拉开始写 `loading` payload；完成/超时/熔断后重算并 updateWidget

## 3. home_widget 数据桥（Flutter）

- [x] 3.1 `pubspec.yaml` 增加 `home_widget` 依赖
- [x] 3.2 新增 `home_widget_payload.dart`：JSON schema（state/header/visual/rows）序列化
- [x] 3.3 新增 `home_widget_sync.dart`：读 history + catalog + baby → predict → `HomeWidget.updateWidget`
- [x] 3.4 挂钩：历史 WS/本地变更、persist、登录、登出（empty）、宝宝 save 后调用 sync
- [x] 3.5 新增 `AppDebugLog.homeWidget` + logcat 脚本 + README Debug 表三联改
- [x] 3.6 历史 `_setItemsNow` 立即 `scheduleHomeWidgetSync`（single-flight）；结束计时 `replaceRecordImmediate` 绕过飞行动画冻结

## 4. App 内预览与引导（可选但建议）

- [x] 4.1 设置页或独立入口：展示即将发生事件列表（与小组件同源 builder）
- [x] 4.2 添加小组件简短引导文案 + 触发 `ensureWidgetHistoryDepth`

## 5. Android 小组件

- [x] 5.1 注册 small/medium/large AppWidget（Glance 或 RemoteViews），读取 home_widget 共享 JSON
- [x] 5.2 实现假玻璃马卡龙布局：头部、active/predict 行、loading/empty 态
- [x] 5.3 native 渲染时计算 overdue/upcoming/elapsed 与 header 月龄
- [x] 5.4 `AndroidManifest.xml` 注册 receiver；点击 PendingIntent 打开 App
- [x] 5.5 更新 `proguard-rules.pro` `-keep` 新组件
- [x] 5.6 本地验证 `flutter build apk --release` 通过

## 6. iOS 小组件

- [x] 6.1 新建 Widget Extension target + App Group entitlements（Runner + Extension）
- [x] 6.2 SwiftUI：small/medium/large 三布局，假玻璃 token 常量与 Android 对齐
- [x] 6.3 TimelineProvider：读 App Group JSON；按 nextAt 排 refresh entry
- [x] 6.4 点击 `widgetURL` 打开 App（未登录→登录）
- [ ] 6.5 TestFlight 验证三尺寸与跨日月龄（CI 自动添加 Extension；见 `ios/PangbaoWidget/README.md`）
- [x] 6.6 无 Mac CI：ensure_pangbao_widget_target + 双描述文件签名 + pangbao URL Scheme + Secret 校验

## 7. 手工验收

- [ ] 7.1 有历史数据：medium 展示头部 + active 优先 + overdue 排序 + 相对文案随时间变
- [ ] 7.2 首次添加 widget：loading「正在准备数据…」→ ready；预拉后预测更准确
- [ ] 7.3 未登录/登出：empty「打开胖宝记录」且无旧事件泄露
- [ ] 7.4 新增记录后桌面 widget 在合理时间内更新（代码已挂钩 sync；需真机确认）
- [ ] 7.5 Android release APK + iOS Extension 双端三尺寸目检

## 9. 小组件 UI v2 与主题联动

- [x] 9.1 横向 tile 布局：small=1 / medium=3 / large=3+近7日折线；👶 统一头像 + 胖宝 logo
- [x] 9.2 payload：`logoFile`、`sparkline`、`visual.isDarkShell`；sync 时从 `resolveVisualBundle` 填 visual
- [x] 9.3 主题变更触发 `scheduleHomeWidgetSync`（设置页 + effectiveTheme listen）
- [x] 9.4 Android：动态渐变背景 + tile logo + Kotlin 折线 Bitmap
- [x] 9.5 修复小组件仅显示圆圈/点击无响应：logo 改 Bitmap 解码、全区域 PendingIntent、布局顶对齐
- [x] 9.6 修复登录后未 sync：`sessionProvider.select(isLoggedIn)` + 冷启动已登录补推 + native fallback
- [x] 9.7 Vivo 兼容：扁平 LinearLayout、纯色背景替代 Bitmap 叠层、标准 Launcher Intent、本地时间解析
- [x] 9.8 背景圆角 18dp + shell 透明度 0.7（Bitmap 渐变底 + payload `shellOpacity`）
- [x] 9.9 方案 A：三尺寸文字与图片统一 2×（header 22sp / logo 72dp / 时间 18sp / 折线 80dp）
- [x] 9.10 方案 B：分尺寸缩放（small 2× / medium 48dp·12sp / large 56dp·14sp+折线）
- [x] 9.11 修复 small/medium 110dp 高度裁切：紧凑文案 + 缩小 logo/字号 + 单行时间

## 10. 小组件 UI v3（分尺寸布局 + 喂养小贴士）

- [x] 10.1 payload 扩展：`hero` / `recentLast` / `tip`；移除 large 折线
- [x] 10.2 hero 仅 top-1 predict；`recentLast` 含 `lastAt`；日更 tip（`/device/history/api/chat`）
- [x] 10.3 Android 三尺寸分布局：模块小标题、large 横向 hero、三列左图右文
- [x] 10.4 iOS SwiftUI 对齐 v3 三尺寸布局
- [ ] 10.5 真机验收三尺寸 + tip 日更（待 7.x）
- [x] 10.6 Vivo 大组件修复：扁平布局、accent 色条替代 recent logo Bitmap、居中与字号调整
- [x] 10.7 Large 双端：header/tip 顶对齐；即将发生+上次记录在剩余区域垂直居中（不做 resize）


- [x] 8.1 `app/README.md` 补充「桌面小组件」章节（添加方式、三尺寸、数据隐私说明）
- [ ] 8.2 实现完成后 `/opsx-archive` 收版
