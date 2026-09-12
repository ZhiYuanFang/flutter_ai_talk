## 1. 开关

- [x] 1.1 新增 `kPredictionLandscapeVoiceEnabled = false`；注释：对话模型未就绪暂关整条横屏助手；翻 `true` 恢复
- [x] 1.2 更新 `kPredictionPortraitVoiceEnabled` 旁注：横屏改由 landscape flag 控制

## 2. 预测页闸门

- [x] 2.1 横屏：flag 为 false 时不挂 `_LandscapeVoiceLifecycleBinder`、不挂 listen chip、不挂字幕 toast
- [x] 2.2 `landscapeVoice` watch 条件改为「横屏且 landscape flag」或「竖屏且 portrait flag」
- [x] 2.3 `syncLandscapeVoiceLifecycle` 的 `want` 乘上 `kPredictionLandscapeVoiceEnabled`

## 3. 验收

- [x] 3.1 手工：横屏预测无 chip / 无唤醒文案 / 不因横屏语音要麦
- [x] 3.2 手工：竖屏仍受 portrait flag 控制（默认仍无入口）
- [x] 3.3 本变更不改 `app/android/**`；不新建 `**/test/**`
