## 1. 主题默认关（app-theme-schedule）

- [x] 1.1 `custom_background_persist.dart`：`loadThemePreferences` 缺省 `scheduleEnabled` 改为 `false`（`clearThemeSchedule` 等路径一并核对）
- [x] 1.2 回归：从未写入 key 的新装/清数据用户默认不自动夜空；已持久化 `true` 用户行为不变

## 2. Compose 视频预览与文案（ucg-compose-post）

- [x] 2.1 `_buildVideoPreview`：有 `localPath` 时始终 `UcgComposeLocalPreview(isVideo: true)`，不因 `objectKey` 切换 CDN
- [x] 2.2 `UcgComposeMediaPreview` 视频分支同步本地优先（若 grid 复用）
- [x] 2.3 移除 `ucg_compose_screen.dart` 视频卡片下「更换视频请关闭…」文案块
- [x] 2.4 手工验证：编辑帖追加视频，等待后台上传完成，首帧不闪、不消失

## 3. 聊天 pending 模型与后台上传（ucg-chat-ui）

- [x] 3.1 扩展 `_PendingChatMedia`（或等价 slot）：`localPath`、`objectKey?`、`cdnUrl?`、`uploadFuture`、`status`
- [x] 3.2 选媒体改为 pick 后立即 setState 本地预览 + `unawaited` 后台 upload（复用 compress + `ucgUploadBytes`）；移除 `_uploadingMedia` 阻塞选图
- [x] 3.3 `_send`：`await` pending 上传完成后再 `sendChatMessage`；发送按钮 in-flight busy / 转圈
- [x] 3.4 上传失败：toast + 中止发送，保留待发送条供用户移除重选

## 4. 聊天布局与待发送条位置（ucg-chat-ui）

- [x] 4.1 将 `_buildPendingMediaBar` 移至 `UcgInputDock` 正上方（消息 `Expanded` 之外）
- [x] 4.2 待发送条展示本地缩略图（`Image.file` / `UcgLocalVideoThumb`），非仅 CDN
- [x] 4.3 视口高度变化时复用/扩展 scroll 补偿（pending 条与 emoji 面板增高）

## 5. 聊天气泡与头像（ucg-chat-ui）

- [x] 5.1 `_ChatBubble`：纯媒体无 `BackdropFilter`/`UcgSurfaceCard`；图文混合时媒体裸、文字气泡
- [x] 5.2 自己纯媒体同样无 primary 渐变气泡；状态图标贴媒体旁
- [x] 5.3 `_ChatAvatar` + `_ChatPeerHeaderTitle`：点击跳转 `UcgUserProfileScreen`（自己/对方 peerId）

## 6. 聊天 emoji 交互（ucg-chat-ui / keyboard bridge）

- [x] 6.1 确认无键盘时 emoji 面板使用 `emojiPanelMinHeight`；列表/dock 随 panel 顶起
- [x] 6.2 表情模式点击消息列表/外部：`dismiss` 或等价逻辑收起 panel，保留 controller 草稿
- [x] 6.3 回归：键盘 ↔ emoji 切换、发送、attach 互不回归

## 7. 个人主页（ucg-profile）

- [x] 7.1 `UcgMyPostTimelineItem`：正文 `maxLines: 2` + `TextOverflow.ellipsis`
- [x] 7.2 `UcgProfileShell`：下调 `flexibleTopPad` / `_headerExpandedHeight` 常量，减少顶部空白
- [x] 7.3 真机目视：owner Tab 与 viewer 页均无上移后 overlap 或 morph 断裂

## 8. 校验

- [x] 8.1 `openspec validate ucg-chat-media-profile-polish` 通过
- [x] 8.2 手工路径：聊天选图→本地预览→发送 await；纯媒体无气泡；点头像进主页；compose 编辑视频不闪
