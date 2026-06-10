## Context

- **Compose** 已具备 `UcgComposeMediaSlot` + 后台上传 + 发表前 `ensureAllUploadsDone`（`ucg-compose-bg-upload-publish-theme`）。
- **Chat** 仍调用 `ucgPickAndUploadChatMedia` 阻塞至上传完成，待发送条 `_buildPendingMediaBar` 放在消息 `ListView` 上方。
- **视频编辑闪烁**：`_buildVideoPreview` 在 `objectKey` 写入后切 `UcgNetworkImage(视频 CDN URL)`，非 poster，导致闪一下且首帧丢失。
- **主题**：`theme-schedule-opt-out-ui` 规定缺省 `scheduleEnabled=true`；现产品要求新用户默认关。
- **键盘**：`ucg.chat` 使用 `UcgPageComposerChrome` 内联 emoji；`detach` 在非 force 时跳过 emoji 模式；待发送条位置与 `keyboard-overlay-composable-config` 旧 spec 冲突。

## Goals / Non-Goals

**Goals:**

- 聊天多媒体与 compose 同一语义：本地先展示、后台传、发送 await。
- 修正 compose 视频预览闪烁；去掉无用提示文案。
- 聊天 UX：裸媒体、点头像、emoji 预设高/外部收起、待发送条贴 dock。
- 个人主页 2 行省略 + 顶栏上移。
- 新用户默认不自动夜空。

**Non-Goals:**

- 抽象跨模块「统一 PendingMedia」公共 package（可复用 compose slot 逻辑，不强制新类型层）。
- 聊天多图/多视频（仍单附件）。
- 修改已开启自动夜空用户的偏好。
- 服务端 poster/thumbnail 字段。

## Decisions

### 1. 聊天 pending 模型

**决策**：在 `ucg_chat_screen.dart` 内引入 `_ChatPendingMedia` 扩展（或薄封装），字段对齐 compose slot 子集：`localPath` / `localBytes?`、`objectKey?`、`cdnUrl?`、`isVideo`、`uploadFuture`、`status`。

**理由**：单附件场景不需完整九宫格；与 compose 上传函数 `ucgUploadBytes` + compress 复用同一管线。

**流程**：

```
pick → 建 slot（localPath）→ setState 展示缩略图
     → unawaited(uploadChatPendingSlot(...))
send → await ensureChatPendingUpload() → sendChatMessage(imageKey/videoKey)
```

**备选**：继续 `_PendingChatMedia` 仅 objectKey — 无法本地先展示，弃用。

### 2. 待发送条布局

**决策**：从 `Expanded > Column > _buildPendingMediaBar` 移到 `UcgInputDock` 同级，结构为：

```
Column(
  Expanded(messages),
  _buildPendingMediaBar(),  // 贴 dock 上沿
  UcgInputDock(...),
)
```

**理由**：符合「输入层上方」产品描述；消息列表 scroll 逻辑已有 viewport 高度监听，需把 pending 条高度计入 dock 区域变化（与 emoji 面板类似）。

### 3. 纯媒体无气泡

**决策**：`_ChatBubble` 拆分渲染：

- `text.isEmpty && (hasImage || hasVideo)` → 仅 `_MediaImage` / `_MediaVideo`，外包 `ConstrainedBox`，**无** `BackdropFilter` / `UcgSurfaceCard`。
- 有文字 → 文字包气泡；媒体可在气泡外上方（微信风格）或媒体不包、文字单独包 — **采用媒体在上无底色、文字在下有气泡**（混合消息）。

**自己/对方一致**，均裸媒体。

### 4. 头像跳转

**决策**：

- 消息行 `_ChatAvatar` 包 `GestureDetector` → `Navigator.push(UcgUserProfileScreen(userId: ...))`。
- 顶栏 `_ChatPeerHeaderTitle` 整行或头像+昵称可点 → 对方 `peerId`。
- 自己头像：`ucgCurrentUserIdProvider`；对方：`conversation.peerId`。
- 与 `requireUcgWxAccount` 无关（浏览资料可读）。

### 5. Compose 视频预览

**决策**：`_buildVideoPreview` 与 `UcgComposeMediaPreview` 对视频分支改为：**有 `localPath` 则始终 `UcgComposeLocalPreview(isVideo: true)`**；仅 remote-only（编辑已有帖、无 local）才用网络 poster/占位。

**理由**：根因是 CDN 视频 URL 当图片加载；本地优先与 compose 图片策略一致。

### 6. 主题默认值

**决策**：`loadThemePreferences` 中 `sp.getBool(_kThemeScheduleEnabledKey) ?? false`；**不** migration 批量改已有用户 key。

### 7. Emoji 无键盘 + 外部收起

**决策**：

- 无 `lastKeyboardInset` 时沿用 `KeyboardOverlayMetrics.emojiPanelMinHeight`（200），`UcgPageComposerChrome` 已有，需确认 chat 列表随 panel 顶起。
- 外部点击：`KeyboardDismissScope` 调用 `dismiss(force: true)` 时，除 unfocus 外须将 `_target` 重置，使 emoji 面板隐藏；若当前 `detach(force:true)` 已足够则仅补 chat 场景回归；若仍不收起，增加 `hideEmojiPanel()`：`_target = keyboard` + `notifyListeners` + unfocus，**不**清 controller。

**理由**：产品要求等同收键盘，保留输入草稿。

### 8. 个人主页布局

**决策**：下调 `flexibleTopPad`（如 leading 时 48→32）及/或 `_headerExpandedHeight` 常量（约减 16–24dp）；动态文案 `maxLines: 2` + `TextOverflow.ellipsis`。

**备选**：改 NestedScrollView 结构 — 改动面大，先调参。

## Risks / Trade-offs

- **[Risk] 待发送条移到底部后消息列表 viewport 变化** → 复用现有 `_onListViewportHeight` / scroll 补偿逻辑，pending 条高度变化时触发与 emoji 相同处理。
- **[Risk] 发送 await 时用户重复点发送** → `_send` 入口加 in-flight guard；发送按钮 `busy`。
- **[Risk] 本地 path 在 Android 临时文件被清理** → 发送前若 local 失效且 objectKey 未完成，toast 并中止（与 compose failed 一致）。
- **[Risk] 修改 theme 默认值与 `theme-schedule-opt-out-ui` spec 冲突** → 本 change MODIFIED delta 覆盖「默认开启」场景。
- **[Risk] 撤销「列表顶 prefab strip」与 archived spec 不一致** → MODIFIED `ucg-chat-ui` 明确新位置。

## Migration Plan

- 纯客户端发版；无 DB/API 迁移。
- 老用户 `theme_schedule_enabled=true` 不受影响。
- 回滚：还原默认值与 UI 布局即可。

## Open Questions

- 混合消息（图+文）：媒体裸 + 文字气泡分开展示（本设计默认）；若需整段单气泡再议。
- 个人主页上移幅度需真机微调，tasks 中以常量具名便于 A/B。
