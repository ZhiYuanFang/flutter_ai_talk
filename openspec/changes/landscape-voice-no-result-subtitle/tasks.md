## 1. 退下音频资源

- [x] 1.1 从硬件 `exit_dialog_prompt_b64` 抽取「我先退下了」wav 到 `app/assets/audio/`（可加抽取脚本）
- [x] 1.2 确认 `pubspec` `assets/audio/` 可加载；常量路径与 `playAssetWav` 对齐

## 2. 开听 grace 与空结果退下

- [x] 2.1 「我在」播完后再延迟再 `beginListen`；必要时加长 pause→播报间隔以减轻片头裁切
- [x] 2.2 开听后宽限窗口内忽略 `asr_no_result`（打 `[LandscapeVoice]` 日志）
- [x] 2.3 `asr_no_result`（宽限外）：展示「我先退下了」、播退下音、再 `_finishTurn`

## 3. 字幕弹幕 UX

- [x] 3.1 `_LandscapeVoiceSubtitleToast`：随内容宽度、maxWidth、softWrap 换行
- [x] 3.2 provider：字幕变更重置 3s Timer，超时清空 `subtitle`

## 4. 退下后再次唤醒

- [x] 4.1 `LandscapeWakeWord.resume`：释放旧 stream、超时开麦、失败可观测；返回是否成功
- [x] 4.2 `_finishTurn` / 退下播完：确保 chat 已停麦 → 短延迟 → resume，失败则重试再 fallback `start`；更新左下角

## 5. 验收

- [ ] 5.1 真机：完整「我在」→ 有时间说话；空结果退下音；弹幕 3s；退下后可再次语音唤醒
