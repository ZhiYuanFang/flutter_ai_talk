## Context

智能预测页当前在「接下来3小时」之上渲染 `_CareAlertPanel`（资格进度 / 开通引导 / 跑马灯），并由 `UcgHomeShell._ensureCareAlertOnPredictionVisible`、`predictionCareAlertProvider` 跨日边沿、`home_widget_sync` 等路径自动 `ensureLoaded` 拉取 `/device/api/care-alert/daily`。日接口含 LLM 编排，耗时长。桌面 large 小组件含 tip 区，且 recent 槽位硬编码 0..2。

本变更把「值得留意」迁入独立 AI 分析页、改为手动日刷，并调整三小时入口与小组件。

约束：`openspec/project.md`（副作用 HTTP、Android Release/R8、主题 `AppColor`、不自动新建测试）；基线 `v2.1.0` 的 `home-feed-upcoming-widget` / `widget-tip-companion-bridge`；既有未归档能力名 `prediction-care-alert` / `smart-prediction-page`。

## Goals / Non-Goals

**Goals:**

- 预测首页去留意卡；三小时全量文案 + 「AI分析」入口。
- AI 分析页：喂养记录分析（门闸 + 列表 + 手动「AI智能分析」/「正在思考中」/ 日成功限次）+ 成长轨迹浅占位。
- 全局停止 daily 自动拉取；仅分析页用户点击触发。
- 小组件去 tip；large recent 最多 6（两行×3）。

**Non-Goals:**

- 成长轨迹真实问答 / 后端 API / 周预测内容。
- 改写 care-alert 服务端契约或详情页忽略/追问语义。
- 恢复或替换陪伴侧「小组件 tip 注入」内容源（无 tip 则不注入）。
- medium 小组件 recent 扩到 6。
- 新建 `**/test/**`。

## Decisions

### D1. 页面与路由

- 新增 `ConsumerWidget`/`ConsumerStatefulWidget` 分析页；go_router 路径建议 `/prediction/ai-analysis`。
- 详情仍 `/prediction/alert` + `CareAlertEventItem` extra。
- **备选**：用 bottom sheet 承载分析 → 否决（两模块 + 长思考态更适合全页）。

### D2. 预测页 chrome

- 删除绑定热态下 `_CareAlertPanel` 分支；Auth 冷态滑动引导大卡可保留（与留意无关）。
- `_NextThreeHoursTimeline`：移除 `_ExpandToggle` / 折叠行数；标题 `Row` 右侧放独立手势「AI分析」圆角 pill（`GestureDetector`/`InkWell` + `behavior`，避免冒泡到整卡喂养跳转）。
- **备选**：整卡改点进分析 → 否决（破坏既有点进喂养）。

### D3. daily 拉取边界（副作用 HTTP）

- 移除 / 空实现：`UcgHomeShell` 进预测 ensure daily、`predictionCareAlertFetchAllowed` listen 触发的 daily、`predictionCareAlertProvider` 跨日 `force` ensure、`home_widget_sync` 内对 daily 的 ensure。
- 保留：进 **AI 分析页** 时可 `ensure` eligibility（及 catalog/VIP settle 若开通门闸需要）；**不得**因此自动打 daily。
- 手动刷新：`ensureLoaded(force: true)` 或专用 `refreshDailyManual()`；single-flight 已有 `_inFlight` 须保留，防止连点。
- 成功判定：repository 返回非 null 列表（含空列表）即业务成功；null / 抛错为失败。

### D4. 「今日已刷」持久化

- SharedPreferences（或既有 store 风格）键：上海日历日 `careAlertShanghaiDayKey()` + deviceNo（或仅 dayKey 若产品接受换设备同日共享——**默认 dayKey+deviceNo**）。
- UI：`manualRefreshSucceededToday` → 隐藏「AI智能分析」；跨日自动恢复。
- **备选**：仅用 `state.ready && dayKey==today` → 不足（升级前自动拉过的 ready 会误藏按钮；且失败后 ready 语义混乱）。显式「成功手动刷新日」更贴产品文案。

### D5. 喂养分析模块 UI 态

```
未合格 / 资格失败 / loading → 进度或重试（点进喂养或 force eligibility）
合格未开通 → 开通中心 CTA
已开通且今日未成功刷 → 列表（可空）+ 「AI智能分析」
loading daily → 「正在思考中」（CTA 禁用或隐藏）
今日已成功刷 → 列表、无 CTA；条目 → 详情
失败 → 回未刷 CTA，可提示失败（不 Toast「请明日再来」）
```

成功 Toast 文案固定：「今日值得留意刷新成功，请明日再来」。

### D6. 成长轨迹占位

- 同页第二卡片：标题「成长轨迹预测」（或产品同等文案）+ 一行「即将上线」类说明；无按钮交互。
- **不做** 假是/否对话。

### D7. 小组件 tip 移除

- Flutter sync：**不再** `persistWidgetTipSnapshot` / 填 `payload.tip`；可写空 tip 或省略字段。
- Native large/medium：`widget_tip_section` 恒 `GONE`（或布局删除区；优先 GONE 降低破坏面）。
- `widget-tip-companion-bridge`：无 tip 缓存则进陪伴不注入；**不得**为桥接重新拉 tip HTTP。
- Showcase / large preview：去掉 tip 展示若有。

### D8. large recent 6

- Dart：`buildWidgetRecentLast(..., count: 6)`（large 路径）；hero 排除逻辑不变。
- Android XML：在 `widget_recent_row` 下增加第二行 `widget_recent_row_2`，槽位 id `widget_recent_3..5`（镜像 0..2 结构）。
- Kotlin：`slots = min(size, 6)`；`bindRecentItem`/`hideRecentSlot`/`recentContainerId` 扩到 0..5。
- Flutter `home_widget_large_preview.dart`：`take(6)`，两行 UI。
- medium 仍 3，不变。
- Release：改 `app/android/**` 后必须 `flutter build apk --release`。

### D9. 主题与日志

- 新页 chrome 用 `AppColor.panelGlass*` / 既有卡片模式，禁止硬编码灰白。
- 继续用 `AppDebugLog.careAlert`；不新增 tag 除非必要。

## Risks / Trade-offs

- [进预测不再预拉 daily → 分析页首次点分析等待长] → 用「正在思考中」过渡；接受产品取舍。
- [桌面 tip 消失 → 陪伴注入少一条路径] → 符合「去掉 tip」；首页 tip / 问候逻辑不动。
- [large 两行 6 槽增高挤占 Vivo 等 ROM 高度] → 保持单格尺寸、仅加一行；真机目视验收。
- [旧客户端 prefs 无「已刷日」→ 升级后仍显示 CTA，即使内存曾 ready] → 正确；用户再点一次即可。
- [遗漏某处 auto ensure] → tasks 列清单（shell / provider / sync / ensureProvider invalidate）；实现后 grep `ensureLoaded` / `care-alert/daily`。

## Migration Plan

1. 先停 auto daily + 预测页去卡 + 分析页门闸与手动刷（可先不改 widget）。
2. 再改 tip 移除与 large 6 槽；本地 release APK。
3. 回滚：git revert 本 change；prefs 新键无害可留。

## Open Questions

- （无阻塞）分析页 AppBar 标题最终文案：「AI分析」 vs 「智能分析」——实现默认「AI分析」。
- 成长轨迹占位标题默认「成长轨迹预测」；产品若改名仅改文案。
