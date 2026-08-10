## Context

基线 `/home` 为陪伴 | 喂养 | UCG；首页 tip SSE 与 tip→陪伴桥并存；桌面小组件 tip 经 `resolveWidgetTip` / history chat 写入日缓存（trim + full）。本次用本地预测占 page 0、拆除首页 tip SSE；陪伴改为 **预测页顶部小组件 tip 卡 → push**，并保留实现源码。

## Goals / Non-Goals

**Goals:**

- PageView page 0 = 智能预测页（懒挂载、右滑、返回先回喂养）。
- 预测页顶：有当日 widget tip cache 时展示文案卡（可用 trim）；无 cache **隐藏**整卡；点击 **push** 陪伴（本 change **唯一**陪伴入口）；进陪伴注入用 **full**。
- 预测列表/折线/推演开关；喂养顶栏本地「最近下一步」预测贴士（与 tip 卡分离）。
- 拆除 tip SSE / tip 球卡；保留小组件 tip 拉取与陪伴源码。

**Non-Goals:**

- 不删除陪伴/Clinic 源码；不把陪伴挂回 PageView；不扩 4 页。
- 不另做设置中心陪伴入口（本阶段）。
- 不改 `event_next_predictor` 算法、不另抽预测工具层；不改小组件 tip 后端契约。
- 不新建 `**/test/**`。

## Decisions

1. **pager 与陪伴分离**  
   page 0 = 预测；`/pangbao` → 预测页。陪伴仅经 tip 卡 push（`PangbaoAiScreen` 或等价路由），返回 pop。

2. **双贴士互不替代**  
   - 喂养顶栏：本地 `predictAllUpcoming` + skip。  
   - 预测页顶卡：小组件 tip cache（与桌面同源）。

3. **tip 卡与注入**  
   - 展示：当日 cache 非空才渲染；文案可用 trim。  
   - 进入陪伴：复用既有 inject 路径，优先 **full**（`kWidgetTipFullTextKey`），并 activate Clinic WS。  
   - 仅打开预测页/喂养页：**不得**副作用注入。

4. **预测列表**  
   推演开关默认 ON、本地持久；关则置灰/无下次/无折线；行内 `EventLogo`。折线窗口 `[now-6d, now]`：每天至多一点（occurrence TOD 距 `nextAt` 时刻最近），虚线连接；轴为日×时刻。进页后台预拉历史跨满 7 天（single-flight，与小组件 30 日预拉独立）；预拉中图区「正在加载中」。

5. **视觉**  
   预测页玻璃拟化；不继承 companion soft neumorphism 作主表面。

## Risks / Trade-offs

- **[Risk] 无 tip 时无法进陪伴** → 产品接受；卡隐藏即无入口。  
- **[Risk] tip 拉取失败日** → 沿用 widget tip fail-day / 旧 cache 策略。  
- **[Risk] pager 旧入口残留** → 清 `requestPage(companion)` / 设置入口。  
- **[Trade-off] 保留陪伴源码** → 换 push 复用成本低。

## Migration Plan

1. page 0 换预测页；保留陪伴源码。  
2. 顶卡读 tip cache + push 陪伴 + full 注入。  
3. 拆除 tip SSE/球卡；喂养顶栏本地预测贴士。  
4. 验收：有/无 tip 卡、点卡进陪伴、注入 full、无其它陪伴入口。

回滚：page 0 改回挂载陪伴；tip 面板按需。

## Open Questions

- 无阻塞项。
