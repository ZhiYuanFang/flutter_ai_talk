## Context

- `fetchPost(postId, {lat, lng})` 与 `ucgPostDetailProvider` 已支持坐标 query。
- `UcgPostDetailScreen` 在 `initState` 调 `_refresh()`，内部直接 `repo.fetchPost(widget.postId)`，绕过 Provider。
- 广场 Feed 通过 `ensureUcgLocationForDistance` 获取坐标；详情按 `defer-ucg-location-until-use` design 应使用 `readCurrentCoordsIfGranted()`（Provider 内已实现），不在详情弹定位申请。
- 详情页除帖子外还加载点赞列表、评论、作者关注态，当前均为 `_refresh()` 内顺序请求。

## Goals / Non-Goals

**Goals:**

- 帖子主体加载统一走 `ucgPostDetailProvider(postId)`，使 `GET /posts/{id}` 在已授权时附带 `lat`/`lng`。
- 下拉刷新、编辑返回、重试与 `ucgPostsChangedProvider` 触发的失效路径均经 Provider 重新拉帖。
- 保留 `seedPost` 首帧占位，避免从 Feed 进入时的白屏闪烁。
- 点赞/评论/关注等交互行为与现 UI 一致。

**Non-Goals:**

- 不为点赞/评论/关注新建 Family Provider。
- 不在详情页新增定位 consent 弹窗。
- 不修改 `fetchUserPosts` / 个人主页列表的距离展示。
- 不改动 Repository 或网关 API 契约。

## Decisions

### 1. 帖子数据：Provider 为唯一网络来源（方案 B）

**选择**：详情页消费 `ucgPostDetailProvider(widget.postId)`，删除 `_refresh()` 内直接 `fetchPost`。

**理由**：Provider 已封装坐标读取与 `ucgPostsChangedProvider` 联动；避免 screen/provider 双轨逻辑再次分叉。

**备选 A（最小改）**：仅在 `_refresh` 加 `readCurrentCoordsIfGranted` — 改动小但 Provider 仍闲置，长期易回归。

### 2. 展示帖：`AsyncValue` + `seedPost` 合并

**选择**：

- `build` 中 `ref.watch(ucgPostDetailProvider(widget.postId))`。
- 展示用 `post = async.value ?? widget.seedPost`（Provider 加载中/失败时仍可用 seed）。
- Provider `data` 到达后覆盖 seed（网络数据含最新 `distanceMeters` / `likedByMe`）。

**理由**：与现有「带 seed 进详情」导航方式兼容。

### 3. 刷新：`invalidate` + 并行加载附属数据

**选择**：`_refresh()` 改为：

1. `ref.invalidate(ucgPostDetailProvider(widget.postId))`
2. `await ref.read(ucgPostDetailProvider(widget.postId).future)`（或 `refresh` 等价）
3. 帖子成功后并行/顺序拉 `fetchPostLikes`、`fetchComments`、条件性 `fetchProfile`（逻辑从现 `_refresh` 抽出为 `_loadAncillary(UcgPost post)`）

**理由**：RefreshIndicator、`onPressed: _refresh`、编辑返回共用一条路径。

### 4. 点赞等局部突变：乐观更新保留在本地 state

**选择**：`_toggleLike` 等仍 `setState` 更新当前展示帖的 `likedByMe` / `likeCount`；不为此 invalidate Provider。

**理由**：减少不必要的详情全量 reload；与现行为一致。编辑/删除仍 bump `ucgPostsChangedProvider`（删除已有）。

### 5. Provider 微调

**选择**：保持 `ucgPostDetailProvider` 实现不变，仅确认 `ref.watch(ucgPostsChangedProvider)` 在 invalidate 场景下行为符合预期；若 screen 改为 watch，initState 不再 `unawaited(_refresh())`，改由 Provider 自动首载 + `_loadAncillary` 在 `ref.listen` 或 post 就绪后触发。

**首载附属数据**：`ref.listenManual` / `initState` 后首帧 `ref.listen` — 当 Provider 首次 `data` 时调 `_loadAncillary`；避免重复请求可用 `_ancillaryLoadedForPostId`  guard。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| Provider 与本地 optimistic `_post` 状态冲突 | 展示帖优先 Provider data；optimistic 仅 patch 当前内存对象，下次 refresh 以网络为准 |
| `ref.listen` 导致附属数据重复拉取 | 以 `postId` + post 版本 guard；refresh 时显式重置 |
| 从通知进详情无 seed，Provider 加载慢 | 保持 loading 指示；无 seed 时行为与现网一致 |
| 已授权但从未进广场（无 consent 流程） | `readCurrentCoordsIfGranted` 仍可读 OS 已授权坐标；符合 design「详情不弹窗」 |

## Migration Plan

单 PR Flutter 改动；无后端/配置发布依赖。回滚：恢复 `_refresh` 直接 `fetchPost` 即可。

## Open Questions

（无 — 方案 B 已在 explore 阶段确认。）
