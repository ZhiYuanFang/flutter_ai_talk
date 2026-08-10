## 1. 主页 PageView 页序与返回锚点

- [x] 1.1 将 `HomePagerPage` 调整为 `feeding=0`、`prediction=1`、`ucg=2`，并全库核对 `requestPage` / 裸索引调用点
- [x] 1.2 更新 `UcgHomeShell`：默认着陆预测、冷启动挂载预测、Android 返回锚点回预测、UCG 回主页指向预测
- [x] 1.3 确认 `/pangbao` 等深链仍切到预测页（新 index）

## 2. 预测顶栏身份条

- [x] 2.1 去掉「智能预测」主标题，改为头像 + 昵称 + `formatBabyAgeText` 月龄
- [x] 2.2 仅头像可点跳转 `/settings/baby`（未登录走既有登录门）；保留布局切换等尾部动作

## 3. 宝宝头像本地存储与表单

- [x] 3.1 实现 `BabyAvatarLocalStore`（`documents/baby_avatar/` + prefs 映射），与 `history_media` 隔离
- [x] 3.2 `BabyProfileEditor` 昵称上方居中头像；点击选本地图并复制落盘；空态男蓝/女粉/未知灰
- [x] 3.3 预测顶栏与编辑页共用头像展示；确认「清除历史媒体缓存」不删宝宝头像
- [x] 3.4 （建议）设置只读宝宝卡同步展示头像

## 4. 喂养按钮-only 与设置隐藏语音识别

- [x] 4.1 喂养页移除 `HomeInputModeDock`，锁定 `HomeInputChannel.buttons`，忽略旧 channel 恢复，避免无 UI 的喂养 ASR 自动连接
- [x] 4.2 设置中心隐藏 `SpeechEngineTile`；验证陪伴页语音仍可用

## 5. 验收

- [x] 5.1 手工验收：冷启动落预测、左右滑喂养/UCG、返回锚点、身份条与选头像、清历史媒体后头像仍在、喂养无 dock、设置无语音识别、陪伴语音可用
- [x] 5.2 本变更不改 `app/android/**` 原生时可跳过 release 构建；若实现中触及 Android 原生/清单则补 `flutter build apk --release` 与 proguard
