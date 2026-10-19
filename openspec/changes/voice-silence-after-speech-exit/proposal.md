## Why

预测语音在检测到第一块有效音后会取消 5 秒无声计时，并且不再重装。用户说完又安静下来时，只要还没进入思考，界面会一直停在「请说话…」。思考中不应因静音退下。

## What Changes

- 上行聆听（「请说话…」）期间，静音计时 MUST 从 `beginListen` 成功起算；每块有效音 MUST 把窗口重置为 5 秒，而不是永久取消退下。
- 5 秒内没有新的有效音时，无论本轮是否已经有过有效音，MUST 走「我先退下了」并回到待唤醒。
- 进入思考窗（已提交、回复尚未结束）MUST 取消该计时，MUST NOT 因静音退下；回到上行聆听后再武装。
- 已有有效音后的空 `asr_no_result` 仍 MUST 续听，且 MUST 重新武装这只 5 秒计时，MUST NOT 仅因该事件退下。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `landscape-voice-listen-idle`：有效音改为重置 5 秒静音窗；说完后再静音也退下；思考中不计时。

## Impact

- `app/lib/providers/landscape_voice_provider.dart`：有效音重置 idle，思考开始时取消，空结果续听后重装。
- 无新 HTTP / WebSocket 协议；无 Android 原生工程变更。
