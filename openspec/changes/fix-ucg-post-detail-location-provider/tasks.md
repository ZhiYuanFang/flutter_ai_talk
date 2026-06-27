## 1. Provider 确认

- [x] 1.1 确认 `ucgPostDetailProvider` 已调用 `readCurrentCoordsIfGranted()` 并将 `lat`/`lng` 传入 `fetchPost`（无改动则勾选并注明）
- [x] 1.2 确认 Provider 已 `watch(ucgPostsChangedProvider)`，与编辑/删除后的列表失效策略一致

## 2. 详情页接入 Provider

- [x] 2.1 `UcgPostDetailScreen.build` 改为 `ref.watch(ucgPostDetailProvider(widget.postId))`
- [x] 2.2 展示帖合并逻辑：`async.value ?? widget.seedPost`；loading/error 态与现 UI 对齐
- [x] 2.3 删除 `_refresh()` 内直接 `repo.fetchPost(widget.postId)` 调用
- [x] 2.4 `_refresh()` 改为 `invalidate` + `read(ucgPostDetailProvider(...).future)` 后加载附属数据
- [x] 2.5 抽出 `_loadAncillary(UcgPost post)`：点赞列表、评论、作者关注态（自原 `_refresh` 迁移）
- [x] 2.6 Provider 首载成功时触发 `_loadAncillary`（`ref.listen` 或等价，避免重复请求）
- [x] 2.7 移除 `initState` 中冗余的全量 `_refresh()`，改由 Provider 自动首载 + 附属加载

## 3. 交互与刷新路径

- [x] 3.1 下拉 `RefreshIndicator`、错误重试、编辑返回仍走统一 `_refresh()`
- [x] 3.2 `_toggleLike` 等乐观更新保持本地 `setState`，不强制 invalidate Provider
- [x] 3.3 删除帖子后现有 `ucgPostsChangedProvider` bump 行为保持不变

## 4. 验证

- [x] 4.1 Debug 日志：已授权定位时 `GET /posts/{id}` 含 `lat`/`lng` query
- [x] 4.2 广场卡片进详情 → refresh 后 meta 行距离不消失
- [x] 4.3 未授权 / 拒绝定位：详情仍可打开，无距离
- [x] 4.4 互动消息直进详情（无 seedPost）：加载与距离行为符合 spec
