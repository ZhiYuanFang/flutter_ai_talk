## Why

胖宝用户需在**不打开 App** 的情况下感知「下一次喂养/换尿布/睡眠结束」等节奏。现有首页仅展示历史与今日汇总，**没有**基于历史间隔的下次触发推断，也**没有** iOS/Android 桌面小组件。母婴场景下桌面一眼可见「约多久后该做什么」可显著降低漏记与焦虑。

本变更在 v2.0.3 喂养历史与 `BabyProfile` 基础上，新增**纯客户端**间隔预测与双端标准尺寸小组件，复用 `HomeHistoryStore` / `EventCatalogStore` 本地数据，**不**新增后端 API。

## What Changes

- **事件间隔预测（Dart）**：按 `eventId` 从历史记录推断典型间隔（分 6 时段桶 + 时间衰减权重 + **月龄自适应半衰期**），计算 `nextAt`；进行中计时（`eventNumber==0` 且未结束）不参与间隔计算。
- **小组件展示**：Android + iOS 标准 **small / medium / large**（添加时用户选型）；顶部展示 `{昵称} · {n}个月啦`；假玻璃马卡龙可爱风；全局按 `nextAt` 排序取前 N 行（进行中计时优先占行）。
- **文案与状态**：overdue 为「已超时 · 约 X 分钟/小时/天」（native 渲染时计算）；`loading` 为「正在准备数据…」；未登录或无内容为空态「打开胖宝记录」；点击打开 App（未登录→登录，已登录→首页）。
- **历史深度预拉**：首次启用小组件时后台多拉历史页（目标约 30 天或 10–15 页），single-flight + 失败熔断，满足副作用 HTTP 治理。
- **数据桥**：`home_widget` 包写入 JSON payload；iOS Widget Extension + App Group；Android AppWidget/Glance；小组件进程**不得**发起 HTTP/WebSocket。
- **App 内预览（可选）**：设置或引导页展示即将发生事件列表，便于验证算法后再看 native 小组件。
- **Web**：不在范围（`HomeHistoryStore` 本就不写 Web 盘）。

## Capabilities

### New Capabilities

- `event-interval-prediction`：分时段加权间隔预测、`nextAt` 排序、月龄半衰期、进行中/过期语义。
- `home-feed-upcoming-widget`：双端桌面小组件 UI、payload schema、刷新触发、空态/loading、玻璃拟态视觉 token、deep link。

### Modified Capabilities

- `home-history-pagination`：增加小组件首次启用时的后台深度预拉路径（与 UI 滚动 `loadMore` 共用 merge 逻辑）。
- `side-effect-http-governance`：widget 历史预拉须 single-flight、失败熔断、非 provider 构造自动触发。

## Impact

- **flutter_ai_talk（本仓）**：
  - 新增 `app/lib/data/event_next_predictor.dart`（及月龄/文案 helper）
  - 新增 `app/lib/home_widget/` bridge（payload 序列化、`updateWidget` 编排）
  - 扩展 `home_history_notifier` 预拉与 persist 后刷新 hook
  - `pubspec.yaml` 增加 `home_widget`
  - `app/android/**`：AppWidget provider、manifest、proguard
  - `app/ios/**`：Widget Extension target、App Group entitlements
  - Debug：`AppDebugLog` 新 tag（如 `[HomeWidget]`）三联改
- **基线对照**：复用 v2.0.3 `home-history-disk-cache`、`history-line-display`（进行中判定）、`BabyProfile`；**不**修改 UCG / WS 传输。
- **Release**：Android 原生改动须 `flutter build apk --release` 通过。
