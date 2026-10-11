## 1. 数据层

- [x] 1.1 新增引导视频 DTO（`slot` / `title` / `videoCdnUrl` / 可选 `coverCdnUrl`）与 `GET /cash/app/api/xiaozhi-mcp/guide-videos` 调用（authorized client；过滤无 `videoCdnUrl`）
- [x] 1.2 小智音箱页进页与下拉刷新一并拉取；失败或空 → 本地列表为空（不 Toast；Debug 记 err）

## 2. 入口 UI

- [x] 2.1 在「绑定后可以做什么」玻璃卡底部条件渲染引导行（有项才出现；标题用 `title`；可选封面）
- [x] 2.2 确认购买 howto `?` 与能力正文不受 list 空/失败影响

## 3. 全屏播放

- [x] 3.1 新增全屏播放路由（登录门禁与音箱页一致）；入参 `title` + `videoCdnUrl`
- [x] 3.2 用 `video_player`（或仓内既有模式）播放；离开 dispose；播失败页内提示

## 4. 验收

- [ ] 4.1 Hub 未配置 → 入口不可见；配置 promo/tutorial → 卡底可见且可全屏播
- [ ] 4.2 断网/失败 → 入口隐藏；刷新成功后出现
