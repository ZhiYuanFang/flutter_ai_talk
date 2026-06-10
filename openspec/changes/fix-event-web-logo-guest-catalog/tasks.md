## 1. Web 事件 logo 跨域展示

- [x] 1.1 `EventLogo` Web 网络图启用 `WebHtmlElementStrategy.prefer`（对齐 UCG CDN 策略）

## 2. 游客事件目录加载与重试

- [x] 2.1 `EventCatalogNotifier` 增加 `isRefreshing` / `remoteLoadAttempted` 状态；`bootstrap(maxAttempts: 3)` 接入冷启动与 Home
- [x] 2.2 游客进 Home 后触发 catalog refresh/retry（`ColdStartBackgroundSync` / `HomeScreen` 去掉仅登录重试限制）
- [x] 2.3 `HomeButtonEventGrid` 加载中显示 progress，仅在远端尝试结束且仍空时显示「暂无可用」；`rootEvents` 过滤为空时 fallback

## 3. 消费者适配

- [x] 3.1 更新 `eventCatalogProvider` 引用处（`home_screen`、`trends_screen`、`home_today_summary_panel` 等）
