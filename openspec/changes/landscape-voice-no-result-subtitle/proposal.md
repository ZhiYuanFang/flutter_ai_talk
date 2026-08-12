## Why

横屏唤醒后「我在」播报易被裁切、开麦过早导致服务端立刻 `asr_no_result`，用户几乎没有说话时间；空结果时文案仍是「没听清…」且无本地退下音，与硬件「我先退下了」不一致。字幕弹幕全宽常显、不随内容收窄、无静默自动消失，结束原因也不在左下状态区保留。

## What Changes

- `asr_no_result`：字幕与状态展示 **「我先退下了」**，并播放本地退下提示音（对齐硬件 `exit_dialog` 提示），播完后再回待唤醒。
- 唤醒开听时序：放麦后短延迟再播「我在」；播完后再短延迟开麦；开听后短窗口内忽略过早的 `asr_no_result`（给用户开口时间）。
- 左下/字幕路径展示本轮结束原因（至少覆盖 `asr_no_result`；其它失败短因可读）。
- 字幕弹幕：宽度随文本（上限屏宽边距内）、超长自动换行；文本变更重置计时，**3 秒无新文本则自动消失**。
- 从硬件提示音抽取/登记 `assets/audio` 退下 wav，并更新 `pubspec` 资源声明（若尚未通配）。

## Capabilities

### New Capabilities

- `landscape-voice-turn-ux`: 横屏语音一轮结束（空结果退下音/文案）、开听 grace、字幕弹幕布局与自动消失。

### Modified Capabilities

- （无）基线未合并横屏语音细则；指示灯能力由并行 change `landscape-voice-ws-listen-indicator` 覆盖，本变更不重复改红绿点语义。

## Impact

- 代码：`landscape_voice_provider.dart`、`voice_chat_ws_client.dart`（播报/`playAssetWav`）、`smart_prediction_screen.dart` 字幕 toast、`pubspec.yaml` / `assets/audio/*`。
- 资源：新增退下音（可由 `Arduino/ai-voice` 的 `exit_dialog_prompt_b64` 抽取，类比 `wo_zai`）。
- 无新 pub 依赖；无 Android Manifest / R8 预期变更。
