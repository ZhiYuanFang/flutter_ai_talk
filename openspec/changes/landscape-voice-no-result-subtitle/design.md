## Context

`landscape-voice-ws-listen-indicator` 已落地连接指示与开听超时；真机仍出现：只听到「在」、播完即「没听清」回待唤醒、弹幕常显。硬件在空结果/退出对话时播「我先退下了」（`exit_dialog_prompt_b64`）。产品已拍板：`asr_no_result` → 文案「我先退下了」+ 播该音频；弹幕随宽、换行、3s 无更新消失。

## Goals / Non-Goals

**Goals:**

- 空结果体验对齐硬件退下语义（文案+音频）。
- 降低「无说话时间」：播报前后与开听后的 grace。
- 弹幕可读且不常驻挡内容。
- 结束原因对用户可见（不只闪一下字幕）。

**Non-Goals:**

- 不改服务端 VAD 参数 / chat WS 帧协议。
- 不合并双 AudioRecorder。
- 不改红绿点语义（既有 change）。
- 不强制修复所有 TTS 裁切根因（以延迟与播放完成等待为主）。

## Decisions

1. **`asr_no_result` 路径**  
   收到后：停麦 → `subtitle`+`statusCaption` 设为「我先退下了」→ `playAssetWav` 退下音 → 再 `_finishTurn`。不再使用「没听清，再说一次吧」作为该原因的主文案。

2. **音频资源**  
   新增 `assets/audio/wo_xian_tui_xia_le.wav`（或等价名）；优先从 `D:\work\Arduino\ai-voice\src\prompts\exit_dialog_prompt_b64.*` 抽取（脚本可仿 `extract_wo_zai_wav.py`）。`pubspec` 已有 `assets/audio/` 通配则无需改声明。

3. **开听 grace（写死建议值，实现可微调）**  
   - pause 后 → 播「我在」前：≥200ms（已有可保留/加长）。  
   - 「我在」播完 → `beginListen` 前：再延迟 ~300–500ms。  
   - `beginListen` 成功后：**约 2.5–3s 内忽略 `asr_no_result`**（仍记日志）；窗口外按退下路径处理。  
   备选「仅服务端加长静音」本期不做。

4. **「我在」裁切缓解**  
   放麦稳定后再 `play`；`playAssetWav` 确保完整等到播放结束（必要时检查 `PlayerMode`/先 `stop` 再播）。不以改 wav 内容为主。

5. **弹幕 UX**  
   - 容器：`mainAxisSize.min`，`maxWidth` = 屏宽减去左右 inset。  
   - `Text`：`softWrap: true`，可多行。  
   - Controller：字幕文本变更时重置 3s Timer；超时将 `subtitle` 置空；新文本再出现。  
   - 「我先退下了」同样走弹幕规则（播音期间文本在，播完后若无新文本则 3s 后消失；或播完立即 `_finishTurn` 后仍保留 subtitle 直到 3s——实现选：finish 后不清空 subtitle，仅靠 3s timer）。

6. **结束原因可见**  
   `asr_no_result` 时 `statusCaption` 在退下流程中显示「我先退下了」，播完回待唤醒文案；其它 `TurnEnded(ok:false)` 用短因写 status/subtitle。

7. **退下后再次唤醒**  
   播完退下音后 MUST 可靠 `resume` KWS：先确保 chat 已停麦，短延迟再开 KWS 流；`resume` 失败重试一次，仍失败则 fallback 完整 `start`；失败 MUST 打 `[LandscapeVoice]` 并更新左下角。服务端静音阈值不在本 change 调整。

## Risks / Trade-offs

- **[Risk] grace 过长感觉迟钝** → 2.5–3s 仅忽略空结果，不阻止 ASR partial。  
- **[Risk] 退下音与「我在」同 Player 抢占** → 串行 await play。  
- **[Trade-off] 忽略窗口内的真实空结果会晚退出** → 接受，优先可说话。  
- **[Risk] resume fallback 全量 start 较重** → 仅失败路径；保证可再唤醒优先。

## Migration Plan

1. 抽取退下 wav 入库。  
2. 合入 grace + no_result 路径 + 弹幕。  
3. 合入退下后 resume/重试/fallback。  
4. 真机：唤醒听完整「我在」→ 有时间说话；静音等到窗口后听退下音看文案；弹幕 3s 消失；退下后可再唤醒。  
5. 回滚：恢复旧文案与立即 finish。

## Open Questions

（无）退下文案/音频、弹幕 3s、grace 方向、再次唤醒修复已确认；服务端静音时长由运维另调。
