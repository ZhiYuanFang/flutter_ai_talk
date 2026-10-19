## Context

横屏芯片与竖屏语音球共用 `LandscapeVoiceController`。关键词文件每次模型就绪都会被 `_ensureKeywordsFile` 覆盖，当前行是 `n ǐ h ǎo p àng b ǎo :2.0 #0.25 @你好胖宝`。`KeywordSpotterConfig` 另有 `keywordsThreshold: 0.25` 与 `keywordsScore: 1.5`。`_onWake` 与 `_onBargeInWake` 会先 `await` 播完 `wo_zai.wav`，再 `beginListen`。回合状态写在球旁 `statusCaption`；字幕呼吸动画只在思考态开启。`SherpaLandscapeWakeWord.resume()` 在 `_pcmSub != null` 时直接返回，不会新建流。主壳 `resumed` 只做 HTTP/WS 自愈，不重建唤醒流。

## Goals / Non-Goals

**Goals:**

- 唤醒词只保留「胖宝」，横竖屏同一条链路。
- 唤醒后立刻开听，同时异步播放短「叮」，字幕显示「我在」。
- 「请说话」「连接中」一类回合状态放到字幕上，并沿用思考字幕的呼吸透明度。
- 主壳回到前台、且不在对话回合中时，先 `pause` 再 `resume`，保证麦克风流是新的。

**Non-Goals:**

- 不调高 `:2.0 #0.25`、`keywordsThreshold` 或 `keywordsScore`。
- 不改思考窗打断范围，不恢复播中打断。
- 不改服务端，不改小智音箱。
- 不把这次当成冷启动修复。

## Decisions

1. **关键词只改拼音与展示名。** 新行 `p àng b ǎo :2.0 #0.25 @胖宝`。boost 与 `#` 阈值原样。Spotter 的 `keywordsThreshold` / `keywordsScore` 不改。更短的词会提高误唤醒，这是用户明确接受的代价。
2. **确认音不阻塞开听。** 唤醒与思考窗 barge-in 都先把字幕设为「我在」，再不等待地 `playAssetWav` 播放 `assets/audio/ding.wav`，随即 `beginListen`。不再等待 `wo_zai.wav`。叮声要短、音量低，因为麦克风已经打开，可能被转写。
3. **状态进字幕，失败留在球旁。** 待唤醒「说「胖宝」唤醒我」以及权限失败、引擎失败等可点按重试的文案仍用 `statusCaption`。`请说话`、`连接中`、`语音通道连接中`、`正在接通会话` 以及唤醒确认「我在」进入字幕，并打开与思考字幕相同的呼吸透明度。ASR / 思考 / 回答到达后替换这些状态字幕。
4. **状态字幕不按 3 秒静默消失。** 思考与回答仍按既有 3 秒无变更清空。只要「我在 / 请说话 / 连接中」仍是当前回合状态，字幕必须留着。
5. **回前台必须先停再开。** `UcgHomeShell` 收到 `resumed` 时，若共享语音会话已激活且不在聆听、思考或 TTS 中，则 `ensureMicStopped()`，再 `wake.pause()`（清掉 `_pcmSub`），再 `wake.resume()`（新建 `OnlineStream` 并 `startStream`）。只调用 `resume()` 不够，因为订阅还在时它会直接返回。若 `_finishTurn` 已在做同一套恢复，用 single-flight 跳过，避免两路抢麦。进后台停播、思考窗打断、播中禁止占麦都保持现状。

## Risks / Trade-offs

- [「胖宝」更易误唤醒] → 不提高分数；误唤醒按现有开听与 5 秒无声退下处理。
- [叮声进入上行被转写] → 资源保持很短；不因此推迟 `beginListen`。
- [回前台重建打断正在进行的回合] → 仅在非聆听、非思考、非 TTS 时重建。
- [与进后台 `_finishTurn` 的恢复打架] → 同一把恢复锁，后到的调用看到已在恢复则返回。

## Migration Plan

发布客户端即可。旧关键词文件会在下次模型就绪时被覆盖。回滚是恢复「你好，胖宝」行与「我在」阻塞播放，分数本来就没变。

## Open Questions

无。短「叮」资源在实现时放入 `assets/audio/`，不另选交互方案。
