## Why

UCG 模块在聊天多媒体、发布编辑预览、个人主页布局与主题默认值上存在多处体验断层：聊天仍阻塞式上传且待发送条位置错误；编辑动态视频上传完成后首帧闪烁丢失；纯媒体消息仍包气泡底色；点头像无法进主页；表情面板在无键盘/点外部时行为不完整；个人主页动态文案未折叠且顶部留白过大。同时「自动夜空」对新用户默认开启与产品预期不符。需在一轮变更内对齐聊天与 compose 的后台上传管线，并统一打磨上述可见交互。

## What Changes

- **主题**：`theme_schedule_enabled` 未写入时默认 **关**（仅影响新用户/从未设置者；已持久化 `true` 的老用户不变）。
- **发布/编辑 compose**：视频预览在存在 `localPath` 时 **始终本地首帧**，不因后台上传完成切 CDN 而闪烁；移除视频卡片下方「更换视频请关闭…」提示文案。
- **聊天多媒体管线（本轮必须对齐 compose）**：
  - 选图/选视频后 **立即本地预览**，后台 `unawaited` 上传；
  - 待发送条置于 **输入 dock 层上方**（非消息列表顶）；
  - 点发送时若上传未完成，**发送按钮内转圈**并 await 全部完成后调用 `sendChatMessage`；
  - 选媒体阶段 **不得** 阻塞 attach 或禁用输入（移除选完才预览的模式）。
- **聊天气泡**：纯图片/纯视频消息（含自己发送）**完全无气泡底色**；仅文字（或文字+媒体混合时的文字部分）保留气泡样式。
- **聊天点头像**：消息行 **双方** 头像 + **顶栏** 对方头像/昵称区均可点击，进入 `UcgUserProfileScreen`（自己进「我的」资料、对方进 viewer 资料）。
- **聊天 emoji**：无键盘历史高度时 emoji 面板使用 **预设高度**（`emojiPanelMinHeight`）；表情模式下点击输入区 **外部** 须收起面板（等同收键盘，保留草稿）。
- **个人主页**：「我的动态」时间轴正文 **最多 2 行**、超出尾部 `…`；资料头 **整体上移**，减少顶部空白（调 `flexibleTopPad` / `headerExpandedHeight`）。

## Capabilities

### New Capabilities

（无——行为扩展落在既有能力 delta 内。）

### Modified Capabilities

- `app-theme-schedule`：新用户默认关闭自动夜空（`theme_schedule_enabled` 缺省值改为 `false`）。
- `ucg-compose-post`：视频预览本地优先防闪烁；移除视频更换提示文案。
- `ucg-chat-ui`：待发送条位置、后台上传管线、裸媒体气泡、头像跳转、emoji 无键盘/外部收起。
- `ucg-profile`：动态列表正文 2 行省略；资料壳层顶部间距收紧。

## Impact

| 区域 | 路径 |
|------|------|
| 主题持久化 | `app/lib/theme/custom_background_persist.dart` |
| 发布页 | `app/lib/ucg/ui/ucg_compose_screen.dart`、`ucg_compose_local_preview.dart` |
| 聊天 | `app/lib/ucg/ui/ucg_chat_screen.dart`、`ucg/data/ucg_media_picker.dart`（或新建 chat pending slot helper） |
| 键盘/emoji | `app/lib/ui/widgets/keyboard_input_bridge.dart`、`ucg/ui/widgets/ucg_visual_widgets.dart` |
| 个人主页 | `app/lib/ucg/ui/ucg_profile_shell.dart`、`widgets/ucg_my_post_timeline_item.dart` |

**依赖关系**：聊天上传管线对齐 `ucg-compose-bg-upload-publish-theme` 中 `UcgComposeMediaSlot` / `uploadComposeMediaSlot` 模式；撤销 `keyboard-overlay-composable-config` 中「待发送条在消息列表上方」条款；修正 `ucg-media-preview-selection-ux` design 中「远程视频用 UcgNetworkImage」导致的闪烁根因。

**Out of Scope**：后端 API 变更；历史喂养编辑媒体条带；Gitee/GitHub CI；上传进度条 UI。
