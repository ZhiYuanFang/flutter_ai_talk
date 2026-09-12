## Why

预测首页的「值得留意」跑马灯与进页自动日拉取占空间、抢注意力，且 LLM 日接口很慢；家长更需要在「接下来3小时」旁一键进入独立 AI 分析页，按需触发分析，并把资格/开通门闸与列表详情收拢到该页。桌面大组件同时去掉 tip、扩大「上次记录」候选展示量。

## What Changes

- **BREAKING**：智能预测页 **移除**「值得留意」卡片（含跑马灯与页内资格/开通进度壳）；进预测页 / shell / 跨日 / 小组件 sync **不得**再自动调用 `care-alert/daily`。
- 「接下来3小时」：去掉展开/收起，**全量展示**正文；标题行最右侧增加圆角按钮 **「AI分析」**（有该时间线块即始终显示）；整卡仍点进喂养，按钮单独进 AI 分析页。
- **新增** AI 分析页（路由待定，如 `/prediction/ai-analysis`）：
  - **喂养记录分析**：承接原值得留意资格进度卡、开通引导卡、纵向列表（点进既有 `/prediction/alert` 详情）；未刷过今日显示 **「AI智能分析」**；请求中显示 **「正在思考中」**；业务成功则 Toast「今日值得留意刷新成功，请明日再来」并隐藏 CTA；失败保留 CTA 可重试。
  - **成长轨迹预测**：**浅占位**（标题 + 即将上线类文案），无后端、无假对话流。
- **桌面小组件**：**去掉 tip 文案**（payload 不推 tip、native tip 区不展示）；**large**「上次记录 / recent」由最多 3 槽改为 **两行×3、最多 6**（Flutter payload、Android XML/Kotlin、页内 large 预览对齐）。medium 仍最多 3，不扩槽。
- 资格（连续有效喂养日）与开通功能卡资格 **仍存在**，展示位置改为 AI 分析页喂养模块；eligibility / catalog 可在进分析页时 ensure；**仅** `care-alert/daily` 改为手动。

## Capabilities

### New Capabilities

- `ai-analysis-page`：AI 分析页结构、两模块布局、喂养分析三态 CTA/思考中/日限、成长轨迹浅占位、路由与入口手势隔离。

### Modified Capabilities

- `prediction-care-alert`：日列表由「进预测自动 ensure」改为「仅 AI 分析页手动刷新」；成功日限与失败可重试；列表形态由首页跑马灯改为分析页纵向列表（详情路由不变）。
- `smart-prediction-page`：移除首页值得留意卡；三小时时间线全量展示 + 「AI分析」入口。
- `home-feed-upcoming-widget`：不再向桌面推送 tip；large recent 上限 3→6（两行布局）。
- `widget-tip-companion-bridge`：小组件不再产出 tip 后，不得依赖 tip section 展示；陪伴侧「从小组件 tip 注入」在无 tip 缓存时保持不注入（不恢复 tip 拉取）。

## Impact

- UI：`smart_prediction_screen.dart`（去 `_CareAlertPanel`、改 `_NextThreeHoursTimeline`）；新建 AI 分析 screen；复用 `prediction_care_alert_screen.dart`。
- Provider：`prediction_care_alert_provider.dart`（去掉自动/跨日 force ensure）；`UcgHomeShell` 停掉进页 daily ensure；本地 prefs 记上海时区「今日已成功刷新」。
- 路由：`app_router.dart` 增加分析页。
- 小组件：`home_widget_sync.dart` / `widget_row_builder.dart` / `home_widget_large_preview.dart`；Android `widget_pangbao_large.xml`、`PangbaoWidgetRenderer.kt`（及 medium tip 隐藏）；可能触及 showcase 预览。
- **Android 原生改动**：合并前须 `flutter build apk --release` 通过（见 `openspec/project.md`）。
- 无新后端契约（成长轨迹本期不做）；不自动新建 `**/test/**`。
- 对照基线 `openspec/specs/v2.1.0.md`（`home-feed-upcoming-widget`、`widget-tip-companion-bridge`）；未归档能力名沿用既有 change 中的 `prediction-care-alert` / `smart-prediction-page`。
