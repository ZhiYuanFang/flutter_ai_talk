## 1. 开关

- [x] 1.1 新增 `kPredictionPortraitVoiceEnabled = false`，注释说明：对话模型未就绪暂关竖屏；翻 `true` 恢复；横屏不受影响

## 2. 预测页闸门

- [x] 2.1 竖屏分支：flag 为 false 时不挂载 `_LandscapeVoiceLifecycleBinder`、不挂 `PredictionVoiceEdgeDock`、不挂竖屏字幕 toast
- [x] 2.2 `_LandscapeVoiceLifecycleBinder._sync` 改用 `widget.landscape`，删除写死 `landscape: true`
- [x] 2.3 确认横屏分支仍挂 binder + 监听 chip，行为不变

## 3. 验收

- [x] 3.1 竖屏预测：无语音入口、无定位/麦克风因竖屏语音弹出
- [x] 3.2 横屏预测：监听 chip 仍可用
- [x] 3.3 本变更不改 `app/android/**` 则跳过 release APK
