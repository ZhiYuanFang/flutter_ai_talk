## Why

喂养页长期占据「主页」心智，但用户更常需要看预测与宝宝身份信息；喂养侧语音/文字切换与设置中心语音识别入口也加重噪音。将智能预测居中作为默认主页，并以宝宝头像/昵称/月龄身份条替代「智能预测」标题，同时把喂养收敛为事件按钮记账工具页。

## What Changes

- **BREAKING**：`/home` PageView 页序改为 **喂养(0) | 智能预测(1，默认着陆/主页) | UCG(2)**；Android 返回锚点从「回喂养」改为「回预测」；预测页冷启动即挂载（不再等首次横滑）。
- 智能预测顶栏去掉「智能预测」文案，改为 **宝宝头像 + 昵称 + 月龄**；**仅头像**可点，进入 `/settings/baby`。
- 宝宝信息表单在昵称上方横向居中展示头像；点击可选本地图片，复制到独立本地目录管理；「清除历史媒体缓存」**不得**删除宝宝头像。
- 无自定义头像时展示默认头像：男蓝、女粉；性别未知用中性灰。
- 设置中心 **隐藏**「语音识别」模块（`SpeechEngineTile`）；陪伴页语音输入 **保留**，仍可使用既有/默认引擎。
- 喂养页 **隐藏**输入模式切换 dock，**仅**支持事件按钮操作（忽略历史语音/文字 channel 恢复）。

## Capabilities

### New Capabilities

- `baby-avatar-local`：宝宝头像本地选图、复制落盘、展示空态性别色、与历史媒体缓存隔离。
- `feeding-buttons-only`：喂养页锁定事件按钮输入、移除模式切换 UI。

### Modified Capabilities

- `ucg-home-entry`：三页顺序与默认着陆、返回锚点、懒挂载（预测首屏即挂载）。
- `smart-prediction-page`：顶栏身份条替代「智能预测」标题；头像点击进编辑页。
- `baby-profile-clay-editor-ui`：表单昵称上方居中头像。
- `baby-profile-editing`：头像变更随宝宝资料体验可编辑/持久（本地路径）。
- `android-on-device-asr`（设置语音识别 UI）：设置中心不再展示引擎切换；不影响陪伴语音可用性与引擎持久化读取。

## Impact

- **壳层**：`UcgHomeShell`、`HomePagerPage` 常量/索引、返回与 `requestPage` 语义、UCG「回主页」目标。
- **UI**：`SmartPredictionScreen` 顶栏、`BabyProfileEditor`、`SettingsScreen`、`HomeScreen` / `HomeInputModeDock`。
- **存储**：新增 `baby_avatar/`（或等价）本地目录与映射；`EventMediaLocalStore.clearAll` 边界不变。
- **陪伴**：`PangbaoAiScreen` 语音路径保留；不强制改 Clinic/ASR 协议。
- **测试**：不新建 `**/test/**`；手工验收导航、头像、喂养按钮-only、设置隐藏项。
