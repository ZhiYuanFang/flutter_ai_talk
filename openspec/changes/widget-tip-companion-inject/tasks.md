## 1. 小组件 tip 缓存扩展

- [x] 1.1 在 `widget_tip_cache`（或并列 prefs）增加全文键与 `injected_day` 键；刷新成功时同时写入 trim 与 fullText
- [x] 1.2 提供读取「可注入文案」（优先 full，回退 trim）、判断当日是否已注入、标记已注入的 API；登出清 tip 缓存时一并清理新键（与现有 `clearWidgetTipCache` 对齐）

## 2. 陪伴入口注入

- [x] 2.1 扩展 `_onCompanionEntryActions`：首页 tip 可注入时保持现状并 return；否则若小组件 tip 可注入则追加 `isTipSource`、persist、标记 injected、`markGreetedToday` 后 return
- [x] 2.2 确认清理陪伴记录路径不清除 `injected_day`；用 `AppDebugLog` 记录注入/跳过原因

## 3. 同步路径护栏

- [x] 3.1 确认 `syncHomeWidgetFromRef` / `resolveWidgetTip` 仅更新 tip 缓存与桌面 payload，不向 `PangbaoClinicSessionStore` 追加 tip
- [x] 3.2 确认 `fetchWidgetFeedingTip` 仍走 `POST /device/history/api/chat`，无 tip/generate 切换

## 4. 手工验收

- [ ] 4.1 当日有小组件 tip、无首页 tip：进陪伴出现一条 tip 气泡；再进不再重复；跳过「我来啦」
- [ ] 4.2 同日首页 tip 可注入：只见首页 tip，小组件未标 injected；消费 tip 后再进可见小组件 tip（若仍未 injected）
- [ ] 4.3 清理陪伴记录后同日再进：不因小组件 tip 再次自动注入
