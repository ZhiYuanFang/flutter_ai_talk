# 远场语音真机验收（平放屏朝上 · 2m · 小声）

变更：`app-voice-far-field-capture`

## 环境

- 设备平放于桌面/床头柜，**屏幕朝上**
- 智能预测页 **横屏**，App **前台**
- 用户口部与设备约 **2m**
- 音量：**正常小声对话**（非耳语）
- 各平台至少 1 台代表机型（记录型号与 OS 版本）

## 唤醒（10 次）

每次清晰小声说：**「你好，胖宝」**

| # | Android 唤醒 | iOS 唤醒 | 备注 |
|---|-------------|----------|------|
| 1 | | | |
| … | | | |
| 10 | | | |

通过标准：≥ **8/10** 命中唤醒并进入「请说话…」

## 对话 ASR（10 句）

已唤醒、处于「请说话…」后，每次说一句：

1. 今天宝宝睡了几小时
2. 下一次喂奶是什么时候
3. 帮我记录一次换尿布
4. 宝宝刚才哭了吗
5. 现在几点了
6. 今天的预测准不准
7. 宝宝体重多少
8. 要不要准备辅食
9. 晚上几点睡觉比较好
10. 总结一下今天的情况

| # | Android partial/final | iOS partial/final | chunk avgAbs | session avgAbs |
|---|----------------------|-------------------|--------------|----------------|
| 1 | | | | |
| … | | | | |
| 10 | | | | |

通过标准：≥ **8/10** 出现可用 `asr_partial` 且 final 语义可接受

## 日志

Debug 包过滤：`[LandscapeVoice]`（含 `pcm chunkAvgAbs=`、`effectiveSpeech avgAbs=`）

## 未达标时

1. 记录未通过句与 avgAbs
2. 调整 `AppVoiceRecordConfig.effectiveChunkAvgAbs` 与 Go `pcmEffectiveAvgAbsThreshold`（±20）
3. 复测；**仍不启用** NS、**不掐帧**

## 回归 smoke

- [ ] 首页云端 ASR 近场按住说话仍可用
- [ ] 横屏 5s idle / `asr_no_result` 续听 / barge-in 未因采集变更明显破坏
