## Context

- `UcgComposeScreen` 当前以 `_imageKeys` / `_videoKey` 驱动九宫格，选图路径（相册完成、拍摄、Web 降级、compose 内追加）均在返回前调用 `ucgUploadBytes`，并用 `_uploadingMedia` 阻塞 UI。
- `UcgAlbumPickerScreen` 已支持 `deferUpload: true`（喂养历史编辑在用），返回 `HistoryEditMediaItem` 列表，但 UCG compose 路径未启用。
- 发表成功仅 `Navigator.pop`，`UcgShell` 不切换 Tab；详情编辑 compose 返回后已有 `_refresh()`。
- 主题通过 `themePresetProvider` / `customBackgroundProvider` + `ThemePreferences` 持久化；`ThemePreset.nightSky` 已存在，无按时钟自动切换。

## Goals / Non-Goals

**Goals:**

- 选媒体后秒级本地预览，后台并行上传，用户编辑不被打断。
- 发表、存草稿、AI 润笔在需要 OSS key 时统一 `await` 未完成上传；loading 仅在对应按钮内展示。
- 新帖发表成功进入「我的」并看到新动态；编辑帖回原页面。
- 19:00–05:00 展示夜空主题，05:00 起恢复用户设置基线；设置页改色更新基线。

**Non-Goals:**

- 不改后端 API、dedup resolve/register 语义。
- 不做上传进度条、per-cell 上传角标（保持无感）。
- 不实现跨时区旅行补偿、夏令时特殊规则（仅用设备本地 `DateTime.now()`）。
- 草稿不持久化「仅本地未上传」的媒体 path（存草稿前须等待上传完成，草稿仍只存 objectKeys）。

## Decisions

### 1. 媒体槽模型

**决策**：新增 `UcgComposeMediaSlot`（或复用 `HistoryEditMediaItem` + 侧车状态 Map），字段含：

- `localPath?` — 预览用；远程-only 编辑槽可为 null
- `objectKey?` / `cdnUrl?` — 上传完成后填入
- `isVideo`
- `uploadFuture` / `status` — pending | uploading | done | failed

**理由**：单结构同时服务预览、排序、await、删除与 `_sessionUploadedKeys` 追踪。

**备选**：继续双列表 `_imageKeys` + 并行 `Map<localId, Future>` — 排序与删除易出错，弃用。

### 2. 后台上传触发

**决策**：slot 入列后立即 `unawaited(_startSlotUpload(slot))`；`_startSlotUpload` 内 compress + `ucgUploadBytes`，成功后 `setState` 写入 key 并加入 `_sessionUploadedKeys`。

**理由**：与历史编辑 `_uploadHistoryMedia` 一致，复用 dedup 管线。

**失败**：标记 `failed`；不在九宫格展示失败 UI；发表/润笔/草稿时 `ensureAllUploadsDone()` 对 failed 重试一次，仍失败则 toast 并中止。

### 3. 入口与相册 deferUpload

**决策**：

- `ucgPickMoreImagesForCompose` / `showUcgComposeEntrySheet` 相册分支 → `deferUpload: true`
- 拍摄返回本地 `XFile` path → compose 建 slot 再后台传
- Web `ucgPickMediaWebFallback` 拆为「pick local」+ compose 内后台传

**理由**：`UcgAlbumPickerScreen._complete` 已实现 defer 分支，改动面最小。

### 4. 九宫格预览

**决策**：有 `localPath` 用 `Image.file`；仅远程用 `UcgNetworkImage`；排序仍按 slot 列表索引。

**理由**：用户始终看到刚选的图，无 CDN 闪烁。

### 5. await 网关 `ensureAllUploadsDone`

**决策**：单一 helper，对全部非 `done` slot `await uploadFuture`（或重试上传），返回有序 `imageKeys` / `videoKey`。

调用点：

- `_publish`（发表按钮 `_publishing`）
- `_polishWithAi`（润笔按钮 `_polishing`，在 consent 之后、API 之前 await）
- `_onCloseRequested` → 保存草稿（dialog 按钮 loading）

**`_busy` 范围**：`_publishing || _polishing || _savingDraft`；**不含**后台 uploading，以免误禁发表。

### 6. AI 润笔可见性与 loading

**决策**：`_showAiPolish = 有图片槽且无视频`；与上传状态无关。点击后 `_polishing=true`，先 `ensureAllUploadsDone` 再 `polishPost`；全程仅润笔按钮 icon 位转圈，文案可保持「AI润笔」或「润笔中…」。

**理由**：产品要求用户将上传等待感知为润笔等待。

### 7. 发表后导航

**决策**：

- 定义 `UcgComposePopResult { publishedNewPost, updatedPost }` 或 `bool publishedNew`
- 新帖 `createPost` 成功 → `pop(publishedNew: true)`
- 编辑 `updatePost` 成功 → `pop()` 无 tab 切换
- `UcgShell._openCompose`：`if (result?.publishedNew == true) setState(() => _tabIndex = 4)`

详情 `_openEdit` 保持 `push<void>`，不依赖 pop result。

### 8. 删除与放弃

**决策**：

- 删除 slot：若 `uploading`，取消/忽略 completion 后移除；若 `done`，`deleteMedia`
- 放弃：`_discardSession` 仅对 `_sessionUploadedKeys` 中已完成 key 调 delete；进行中的上传完成后若 slot 已移除则仍 delete 以防孤儿（track cancelled set）

### 9. 定时主题

**决策**：

- 持久化层不变：`ThemePreferences` 存用户**基线**（preset + seed）
- 新增 `AppThemeSchedule.resolve(DateTime now, ThemePreferences baseline)`：
  - `hour >= 19 || hour < 5` → 展示 `nightSkyBundle()`
  - 否则 → `resolveVisualBundle` 用 baseline
- `PangbaoApp` 或顶层 `Consumer`：`Timer.periodic`（如每分钟）+ `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` 重新计算并写入 `themePresetProvider`/`customBackgroundProvider` 的**展示态**
- 设置页 `_applyPreset` / 自定义色：只写持久化基线 + 立即刷新；若当前非定时夜空窗口则直接展示用户选择；若在夜空窗口内手动选色，基线更新，05:00 起用新基线

**备选**：单独 `scheduledOverrideProvider` 与 baseline 分离 — 更清晰，采用。

**时区**：`DateTime.now()` 本地，边界 19:00 含、05:00 含（即 `[19:00, 24:00) ∪ [00:00, 05:00)` 为夜空）。

### 10. Loading 约束

**决策**：禁止 `Stack` 全屏 barrier、`UcgComposeImageGrid.addBusy`、compose 内「上传中…」`Text`；相册完成钮仅在 defer 时不因 OSS 转圈。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 后台上传失败用户无感 | 发表/润笔/草稿时统一检测并重试 + toast |
| 删除与上传竞态产生孤儿 OSS | `_sessionUploadedKeys` + 移除后仍处理 completion |
| 定时主题与用户手动选夜空冲突 | 基线与展示分离；设置页写入基线 |
| App 后台跨过 19:00/05:00 未切换 | `resumed` + 周期 timer 双触发 |
| Web 本地 path 不稳定 | 尽快后台上传；预览用 memory/thumbnail |
| 多图并发上传耗流量 | 与现网一致；发表时若已完成则无额外等待 |

## Migration Plan

1. 落地媒体槽 + deferUpload 入口（可先 feature-flag 内测）。
2. 切换 compose 预览与 `_publish` await 逻辑。
3. 接导航 pop result + shell tab。
4. 定时主题 helper + app 挂载；设置页确认基线写入不变。
5. 手工验证：选图无阻塞、发表跳我的、编辑回详情、19:00/05:00 主题、润笔等待。

回滚：恢复 compose 同步上传路径；移除 schedule provider 即可。

## Open Questions

- 无（探索阶段已确认：编辑回原页、按钮内转圈、润笔合并等待感知、草稿等待上传后存 key）。
