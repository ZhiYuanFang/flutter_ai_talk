## Why

喂养主页左侧「智能陪伴」槽位与添加事件后的 tip SSE 成本高、与本地区间预测能力重叠；用户更需要可解释的下一步时间线与可跳过的预测贴士。将 PageView 左侧改为智能预测页、拆除首页 tip SSE，用同源 `event_next_predictor` 驱动预测页与喂养顶栏贴士；**陪伴实现代码保留**，本阶段唯一入口为预测页顶部的小组件 tip 文案卡（点击 push 进陪伴）。

## What Changes

- **BREAKING**：PageView page 0 不再挂载陪伴；`/pangbao` 改指向预测页；首页 tip→陪伴桥随 tip 面板移除。**不删除**陪伴页面/Clinic 会话/Clinic WS 等实现源码。
- **BREAKING**：删除添加喂养事件后请求 `/device/tip/generate`（SSE）及首页 tip 球/卡面板（`HomeTipPanel`）。
- PageView index 0 改为**智能预测页**（右滑进入，懒挂载）；UI 全新玻璃拟化。
- 智能预测页顶部展示**桌面小组件 tip** 文案卡（读当日 tip cache；无 cache 则整卡隐藏）；点击卡片 **push** 进入陪伴（本 change **唯一**陪伴产品入口）；进陪伴后 tip 注入使用 **full** 文案。
- 智能预测页列表：按 `nextAt` 排序；每行 `EventLogo`、下一点与倒计时；折线为每日一点（贴近 `nextAt` TOD）虚线；进页预拉 7 日历史（图区 loading）；每事件推演开关（默认开，关则置灰/无时间/无折线，本地持久化）。
- 喂养页顶部固定**本地预测**贴士：1 条「最近下一步」；历史变化重算；空态「暂无预测」；「跳过」复用 `WidgetHeroSkipStore`；点非跳过区进预测页。
- 小组件 tip **继续**经既有 history chat 接口拉取并写 cache。
- 预测纯计算继续使用既有 `event_next_predictor`，不另抽公共层。

## Capabilities

### New Capabilities

- `smart-prediction-page`：智能预测页、玻璃 UI、小组件 tip 顶卡（隐藏空态）、点击 push 陪伴、事件列表/折线/推演开关。
- `home-prediction-tip-bar`：喂养顶栏固定本地预测贴士、历史变更重算、空态、跳过与小组件 skip 同源、点击进预测页。

### Modified Capabilities

- `ucg-home-entry`：PageView page 0 改为智能预测页；陪伴不再作为 pager 页。
- `widget-hero-skip`：skip 同时服务桌面 hero 与喂养顶栏预测贴士。
- `widget-tip-companion-bridge`：保留 tip 拉取与 cache；移除「首页 tip 优先注入」；预测页 tip 卡为入口；进陪伴注入用 full；仅打开预测/喂养不得副作用注入。
- `home-tip-on-feed-add` / `home-tip-companion-bridge` / `home-tip-edge-dock` / `home-tip-center-presentation` / `home-tip-gesture-chrome`：随 tip SSE/球卡退役（REMOVED）。

（**不**将 `smart-companion-*` / `companion-*` 标为退役：实现保留，经 tip 卡 push 进入后规格继续适用。）

## Impact

- **Flutter 壳/路由**：`UcgHomeShell`、`HomePagerPage`、`/pangbao`；陪伴经 push 打开，不挂 PageView。
- **UI**：预测页 + 喂养顶栏预测贴士；移除 `HomeTipPanel`；保留 `PangbaoAiScreen`。
- **状态**：拆除首页 tip SSE；推演开关本地存储；widget tip cache 供预测页顶卡与注入。
- **网络**：pager 不因 page 0 激活 Clinic WS；push 进陪伴后再激活；停止 `/device/tip/generate`；小组件 tip HTTP 保留。
- **测试**：不新建 `**/test/**`，手工验收。
