## 1. 壳层与入口替换

- [x] 1.1 将 `UcgHomeShell` PageView index 0 从挂载 `PangbaoAiScreen` 改为智能预测页；保持懒挂载与 KeepAlive
- [x] 1.2 更新 `HomePagerPage` 与所有 `requestPage(companion)` 调用点（含 `/pangbao`）指向预测页
- [x] 1.3 Android 返回：侧页为预测页时先回喂养
- [x] 1.4 冷启动停留喂养不 mount 预测页；**不**因 page 0 激活 Clinic WS
- [x] 1.5 **保留**陪伴源码；关闭设置等其它陪伴入口；唯一入口为预测页 tip 卡 push

## 2. 推演开关与预测消费

- [x] 2.1 本地持久化推演开关（eventId → bool，默认 ON）
- [x] 2.2 `predictAllUpcoming` + 推演开关 + `WidgetHeroSkipStore`，供顶栏与预测页共用（薄 helper 即可）
- [x] 2.3 历史变更触发重算（勿在 provider create 副作用 HTTP）

## 3. 智能预测页 UI

- [x] 3.1 玻璃拟化预测页：列表按 `nextAt`；每行下次点 + 倒计时；右侧推演开关
- [x] 3.2 推演 OFF：置灰、无下次/倒计时、无折线；ON：每日一点虚线折线（日 × 时刻，贴近 nextAt TOD）
- [x] 3.3 页顶小组件 tip 卡：读当日 tip cache；有则展示（可用 trim）；无则整卡隐藏
- [x] 3.4 tip 卡点击：push 打开陪伴；进入后按既有规则激活 Clinic，并优先用 **full** 做 tip 注入
- [x] 3.5 仅打开预测页不得副作用注入；陪伴空态/列表空态与 tip 卡隐藏互不干扰
- [x] 3.6 每行 EventLogo；折线改为每日一点（贴近 nextAt 时刻）+ 虚线；进页预拉 7 日历史，图区 loading

## 4. 喂养顶栏预测贴士

- [x] 4.1 移除 `HomeTipPanel` 挂载与 tip 球/卡相关拖动禁滑耦合（保留 dock 禁滑若需要）
- [x] 4.2 顶部固定本地预测条：1 条最近下一步；空态「暂无预测」
- [x] 4.3 「跳过」写 `WidgetHeroSkipStore` 并 sync 小组件
- [x] 4.4 点非跳过区 → 预测页
- [x] 4.5 删除 `_triggerTipGeneration` / tip SSE 首页路径
- [x] 4.6 顶栏有预测时展示 `EventLogo`；倒计时/已超时文案使用事件色

## 5. tip SSE 清理与文档

- [x] 5.1 清理首页 `tipProvider` / tip SSE 引用；保留 `fetchWidgetFeedingTip` 与 tip cache
- [x] 5.2 确认无 pager/设置等旁路进陪伴
- [x] 5.3 必要时更新 README：左侧为智能预测；陪伴入口为预测页 tip 卡

## 6. 验收

- [x] 6.1 有 tip cache：顶卡可见，点卡 push 陪伴，注入为 full（未注入日）— 待真机/手工确认
- [x] 6.2 无 tip cache：顶卡隐藏，无法从其它路径进陪伴 — 待真机/手工确认
- [x] 6.3 预测列表/开关/折线、喂养顶栏 CRUD/跳过/空态「暂无预测」、无 tip SSE/tip 球 — 待真机/手工确认
- [x] 6.4 未改动 `app/android/**`；release 构建本变更不强制
