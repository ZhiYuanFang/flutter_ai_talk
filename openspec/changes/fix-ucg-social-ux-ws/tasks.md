## 1. 共享 WebSocket 传输层

- [x] 1.1 新增 `app/lib/network/ws_connection_config.dart` 与 `resilient_websocket_client.dart`（phase、config、ping/pong、退避、gaveUp、resume）
- [x] 1.2 将 `RemoteFeedRepository` 历史 WS 逻辑迁移至共享客户端，保持 `history-ws-reconnect` 对外行为不变
- [x] 1.3 将 `UcgRepository` 聊天 WS 迁移至共享客户端，auth 帧保持 `{type:auth, token}`
- [x] 1.4 在 `ucgRepositoryProvider` 监听 `sessionProvider` + wxId 绑定，登录即 `setConnectionDesired(true)`；移除 `UcgShell.dispose` 对全局 WS 的误断开
- [x] 1.5 在 App 生命周期（与 `home_screen` 历史 WS 相同入口）为 UCG 通道调用 `onAppLifecycleResumed`

## 2. 聊天消息去重（`ucg-chat-ui`）

- [x] 2.1 `UcgChatMessage` 增加 `clientMsgId` 字段并在 `fromJson` 解析
- [x] 2.2 `sendChatMessage` 与 `_send` 共用同一 `clientMsgId` 生成逻辑，乐观行携带该字段
- [x] 2.3 `UcgRepository` 处理 `message_ack`、`audit_failed`；`message_delivered` 透出完整 `message`
- [x] 2.4 `UcgChatScreen` 实现 `_upsertMessage`（按 `clientMsgId` 优先），移除盲 `add` 与过早 `_markMessage(delivered)`

## 3. 聊天表情交互（`ucg-emoji-input`）

- [x] 3.1 `UcgPageComposerChrome` 表情按钮：无 binding 时先 attach + requestFocus（不弹 IME）再 `requestEmoji`
- [x] 3.2 `keyboard_input_bridge.dart`：inline composer（`showEmoji==false`）在 emoji 模式允许外部 dismiss
- [ ] 3.3 手工验证：无键盘点表情、表情模式点消息列表/顶栏收起

## 4. Compose 上传防闪（`ucg-compose-post`）

- [x] 4.1 `UcgComposeMediaPreview`：有本地预览时上传完成不立即切网络图；precache 后再切换（可选淡入）
- [x] 4.2 九宫格 `ValueKey` 稳定为 slot id；slot 级 `ChangeNotifier` 或等价局部刷新，去掉整页 `setState` onUpdated
- [x] 4.4 新发视频帖选定后隐藏删除按钮（`editingPost == null` 时无 ×）
- [x] 4.5 compose 视频封面播放按钮与动态列表 `UcgVideoPlayOverlayIcon` 样式一致
- [ ] 4.3 手工验证：编辑动态加图后等待上传完成无明显闪屏

## 5. 相册局部刷新（`ucg-album-picker`）

- [x] 5.1 移除外层包裹整表 `GridView` 的 `ListenableBuilder`
- [x] 5.2 `_AssetCell` 改为 `StatefulWidget`，缩略图 Future 缓存；角标层局部 listen selection
- [ ] 5.3 手工验证：连续点多张选中态切换无全屏闪

## 6. 喂养主页 UI（`home-ai-quota-hint` + `ucg-home-entry`）

- [x] 6.1 `AiQuotaRemainingHint` 或语音区 wrapper：玻璃拟态胶囊样式
- [x] 6.2 `HomeScreen` 语音 stack：额度移至语音球下方，不遮挡 orb 与滑动手势
- [x] 6.5 语音输入面板增高并分区布局，修复额度条导致 `RenderFlex overflow`
- [x] 6.3 `UcgEnterSquareTab` 改为 `ConsumerWidget`，watch `ucgUnreadCountProvider` 在图标左上角绘未读点
- [x] 6.4 确保登录后 WS 长连时停留喂养页也能收到通知并更新拉条红点
- [x] 6.6 登录后喂养页拉条初始拉取未读（`syncUnreadFromWs` + `UcgEnterSquareTab` 激活 repo）

## 7. 收尾

- [x] 7.1 `flutter analyze` 无新增 error（`app/` 目录）
- [ ] 7.2 手工走查：登录停留喂养页收私信、发消息不重复、广场拉条红点、语音额度位置
