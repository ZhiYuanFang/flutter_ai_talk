## Why

`UcgPostDetailScreen` 在 `_refresh()` 中直接调用 `fetchPost(postId)`，未附带 `lat`/`lng`，与 `defer-ucg-location-until-use` 中「Feed/详情读 API 可附带坐标以展示距离」的约定不一致。`ucgPostDetailProvider` 已实现 `readCurrentCoordsIfGranted()` 并传参，但详情页未消费该 Provider，导致 debug 日志中 `GET /posts/{id}` 无坐标 query，详情 meta 行距离在 refresh 后可能消失。

## What Changes

- `UcgPostDetailScreen` 改为通过 `ucgPostDetailProvider(postId)` 加载帖子主体，统一附带已授权坐标。
- 下拉刷新、编辑返回、重试等路径改为 `ref.invalidate(ucgPostDetailProvider)` 触发重新拉取，不再直接调用 `repo.fetchPost`。
- 保留 `seedPost` 作为首帧占位；Provider 成功后以网络数据覆盖。
- 点赞列表、评论、关注态等仍由详情页局部加载（不在本变更扩展新 Provider）。
- 详情页 **不** 新增定位弹窗（继续沿用 `readCurrentCoordsIfGranted` 静默读取，与 `defer-ucg-location-until-use` design 一致）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-square-feed`：补充帖子详情读 API 在已授权定位时必须附带 `lat`/`lng` 的客户端义务，并明确通过 `ucgPostDetailProvider` 实现。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_post_detail_screen.dart`、`app/lib/ucg/providers/ucg_providers.dart`（必要时微调 Provider 依赖/失效策略）。
- **API**：无契约变更；`GET /ucg/app/api/posts/{id}?lat=&lng=` 行为与 Feed 一致。
- **用户可见**：已授权定位用户进入/刷新详情时 meta 行可稳定展示距离；未授权行为不变。
