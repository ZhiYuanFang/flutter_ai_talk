## Context

成长轨迹工作台在 `asking` 阶段对 `free_text`（及 choice「手动输入」）展示 `TextField` +「提交」。语音识别已有：

- `HomeSpeechRecognizer` + `createHomeSpeechRecognizer`（云端 ASR / 系统 STT）
- 全局 `voiceAsrWsClientProvider` → `/voice/asr/ws`（无 JWT；project.md 例外）
- 伴侣页 `pangbao_ai_screen` 已实现按住说话 → 出字再发送

本设计只把同一套按住说话接到轨迹追问输入框，不改 turn API。

## Goals / Non-Goals

**Goals:**

- 追问出现文本输入时提供按住说话，转写为中文填入输入框。
- 共用全局 ASR 单例；轨迹页开听前 ensure 同一 client 已可用。
- 松手后保留「提交」按钮提交答案。

**Non-Goals:**

- 多语翻译或独立「语音翻译」服务。
- `/voice/chat/ws`、横屏对话、TTS。
- 喂养分析 / 护理留意 / 邀码支付弹窗语音。
- 抽取全应用通用 TextField+Mic 组件（本 change 可本地复用伴侣交互模式；抽组件非必须）。

## Decisions

### D1：复用 HomeSpeechRecognizer，不新建 WS

- `createHomeSpeechRecognizer(ref)` → 云端时读 `voiceAsrWsClientProvider`。
- 开听前：若 client 未连接则 connect（与首页策略一致，仍单例）。
- **禁止** 新建并行 `VoiceAsrWsClient`。

### D2：仅文本输入可见时出麦

```
asking + free_text          → TextField + 按住说话 + 提交
asking + choice 默认        → 两按钮，无麦
asking + choice 手动输入    → TextField + 按住说话 + 提交/收起
thinking / result / 非 asking → 无麦
```

### D3：交互对齐伴侣按住说话

- 按下：`prepare`（若需）→ `startSession`；partial 写入输入框或轻量浮层。
- 松手：`endSession` → 最终文本写入控制器；**不**自动 `submitAnswer`。
- 取消：`cancelSession`，不强制清空用户已打字内容（若仅语音未改字则可恢复按下前快照——实现选更简单者并在 tasks 验收）。
- 失败：Toast `HomeSpeechPrepareFailure.message`；仍可键盘输入。

### D4：与 turn 流互斥

- `submitAnswer` 后进入 thinking：**必须**结束/取消进行中的语音会话。
- 新 `question` 到达：既有逻辑会重置控制器；语音会话 MUST 一并 cancel。

### D5：deviceNo / 权限

- ASR `start` 需要 deviceNo；轨迹 turn 本身已依赖绑机。无 deviceNo 时 Toast 既有失败文案，不崩溃。
- 麦克风权限拒绝走既有 `permissionDenied` 文案。

## Risks / Trade-offs

- **[Risk] 首页未挂载时 ASR 未连** → 轨迹页 prepare/开听前 ensure connect。
- **[Risk] 与首页同时按住** → 单例互斥；后开听覆盖前会话属可接受，或开听前 cancel（实现选单例安全路径）。
- **[Trade-off] 不抽共用 Widget** → 轨迹页可复制伴侣手势逻辑；后续再抽。

## Migration Plan

1. 确认制品后 `/opsx:apply`。
2. 发版无服务端迁移；旧客户端无麦仍可键盘作答。

## Open Questions

- （无）产品已确认：语音转中文、按住说话、仅轨迹、全局共用 ASR、松手不自动提交。
