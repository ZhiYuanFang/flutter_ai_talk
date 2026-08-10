## Context

当前 `/home` PageView 为 **预测(0) | 喂养(1，默认) | UCG(2)**；预测顶栏标题为「智能预测」；`BabyProfile` 无头像字段；喂养页通过 `HomeInputModeDock` 切换语音/按钮；设置中心在 iOS/Android 移动端展示 `SpeechEngineTile`。探索结论已拍板：页序 A（预测居中主页）、空态男蓝女粉、仅头像可点、陪伴语音保留。

## Goals / Non-Goals

**Goals:**

- 预测页成为默认主页与返回锚点；喂养退居左侧工具页。
- 预测顶栏身份化（头像/昵称/月龄）；头像进入编辑宝宝信息。
- 宝宝头像本地化管理，与历史媒体缓存隔离。
- 喂养仅事件按钮；设置隐藏语音识别模块；陪伴语音不受影响。

**Non-Goals:**

- 不上传宝宝头像到服务端、不做多端同步头像。
- 不删除喂养语音/ASR 实现源码（可保留但 UI 不可达）；不改陪伴输入模式产品能力。
- 不扩展 PageView 页数；不把陪伴挂回 pager。
- 不新建 `**/test/**`。

## Decisions

1. **页序与常量**  
   `HomePagerPage`：`feeding = 0`，`prediction = 1`，`ucg = 2`。`UcgHomeShell`：`initialPage = prediction`；冷启动 `_predictionEverMounted = true`（或等价首帧即挂载预测）。Android 返回：喂养/UCG → `prediction`；预测根层双击退出。UCG `onBackToFeeding` 改名为语义「回主页」并 `animateTo(prediction)`（实现可保留旧回调名若改动面过大，但行为必须回预测）。

2. **身份顶栏**  
   替换标题「智能预测」；左侧/主区：`CircleAvatar`（或等价）+ 昵称 + `formatBabyAgeText`；右侧保留布局切换等既有动作。仅头像 `GestureDetector`/`InkWell` → `context.push('/settings/baby')`（未登录走既有登录门，与设置入口一致）。

3. **头像存储**  
   新建 `BabyAvatarLocalStore`（或等价）：根目录 `documents/baby_avatar/`，按 `babyId` 复制覆盖；prefs 记相对路径。与 `EventMediaLocalStore`（`history_media/`）隔离；`clearAll` 历史媒体 **不得** 扫描 `baby_avatar/`。换绑/清空 babyId 时删除旧文件。可选：相对路径也可写入本地 baby JSON 字段以便一并序列化——优先独立 store，避免改网关 save 契约。

4. **空态色**  
   复用 `BabyProfileClayTheme.accentBlue` / `accentPink`；`BabySex.unknown` → 中性灰 + `Icons.child_care`。有本地文件则 `FileImage`/`Image.file`。

5. **喂养按钮-only**  
   不渲染 `HomeInputModeDock`；`_inputChannel` 强制 `HomeInputChannel.buttons`，忽略 prefs 恢复的 voice/text。不主动连接喂养 Voice ASR（避免无 UI 的副作用连接）。dock 拖动禁滑逻辑可随 dock 消失而简化。

6. **设置语音识别**  
   `SettingsScreen` 不再挂载 `SpeechEngineTile`（全平台）。陪伴仍通过既有 `HomeSpeech` / prefs 读取上次引擎；无历史选择时用平台默认（Android Vosk / iOS 既有默认）。**不**删除引擎 store 与陪伴语音路径。

## Risks / Trade-offs

- **[Risk] 常量索引对调漏改 call site** → 全库搜 `HomePagerPage.` / 裸 `0/1` 切页；深链 `/pangbao` 仍 `requestPage(prediction)`。  
- **[Risk] 预测冷启动即挂载加重首屏** → 可接受（主页职责）；CareAlert ensure 仍按「预测可见」触发。  
- **[Risk] iOS 用户无法再切换 STT 引擎** → 产品接受；陪伴用持久化/默认值。  
- **[Risk] 头像仅本地、换机丢失** → 明确 Non-Goal；文案无需强调云同步。  
- **[Trade-off] 喂养语音代码残留** → 降低删除面与回归；后续可另 change 清理死代码。

## Migration Plan

- 无服务端迁移。用户升级后默认落在预测页；旧 dock 位置 prefs 可忽略。  
- 回滚：恢复页序/默认着陆与顶栏标题即可；头像目录可残留无害。

## Open Questions

- （已定）unknown 性别空态用中性灰。  
- 设置只读宝宝卡是否同步展示头像：本 change **建议一并展示**以保持一致，非阻断。
