## Why

预测语音从唤醒到开听要先播完「我在」，状态又写在球旁，用户会觉得慢、也不知道自己已经被唤醒。唤醒词「你好，胖宝」偏长。从后台回到前台时，麦克风流偶发已经断了，但客户端仍以为监听还在，唤醒词怎么说都不命中，直到用户点一次球并结束一轮对话。

## What Changes

- 唤醒词改为「胖宝」。关键词文件里的 `:2.0 #0.25` 以及 `KeywordSpotterConfig` 的 `keywordsThreshold`（0.25）与 `keywordsScore`（1.5）MUST NOT 调高。
- 唤醒确认改为短促「叮」，与开听并行，不再等待「我在」播完才 `beginListen`。字幕展示「我在」，让用户知道已经唤醒。
- 「请说话」「连接中」等回合内状态从球旁文案挪到字幕条，并使用与思考字幕相同的呼吸透明度。待唤醒提示仍留在球旁。失败、可点按重试的文案仍留在球旁。
- 主壳 `resumed` 且当前不在对话回合中时，按点球对话结束后的方式先 `pause` 再 `resume` 重建唤醒流。横屏芯片与竖屏语音球共用同一控制器。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `prediction-landscape-voice`：唤醒词改为「胖宝」且不调高分数；确认改为「叮」与开听并行；球旁只留待唤醒与失败文案；回前台重建空闲唤醒流。横屏与竖屏共用该会话。
- `landscape-voice-multi-turn`：续听「请说话…」改由字幕展示；回到待唤醒时的提示改为「胖宝」。
- `landscape-voice-turn-ux`：状态字幕在仍有效时不得按 3 秒静默清空。
- `landscape-voice-barge-in-window`：思考窗打断的确认改为「叮」加字幕「我在」，不再阻塞等待「我在」人声。
- `landscape-voice-listen-idle`：无声计时仍从 `beginListen` 成功起算；锚点场景不再写成先播完「我在」才开听。

## Impact

- `landscape_kws_models.dart` 关键词行；`landscape_wake_word.dart` 分数配置保持不动。
- `landscape_voice_provider.dart` 的 `_onWake` / `_onBargeInWake`、状态文案与回前台重建。
- `landscape_voice_subtitle_toast.dart` 呼吸动画覆盖状态字幕。
- `ucg_home_shell.dart` 的 `resumed` 挂钩。
- 新增短「叮」资源（`assets/audio/`），麦克风权限文案与待唤醒提示里的唤醒词同步改为「胖宝」。
- 不改服务端、不改思考窗打断范围、不改播中禁止打断。
