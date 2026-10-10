## Context

对齐 `go_ai_talk` 后确认：听写 WS **不会**因静音下发业务 `asr_final`；百炼 `sentence_end` 仅经 `onFinal` 再发 `asr_partial`。旧实现下行 `text` 只有**当前句**，且 `preferLonger` 不拼接，导致 Flutter「变成 B、松手 A」。根修在服务端会话全文；Flutter 信任全文并兜底旧服。

## Goals / Non-Goals

**Goals:**

- 单次 utterance 内累积中途 `asr_final`；`onPartial` 始终为累积全文。
- `endUtterance` 在 `commit` 之后收束，返回累积全文（含末段）。
- `project.md` 明确：静音 final ≠ 整轮结束；Feature 不得平行「只认第一个 final」。

**Non-Goals:**

- 关闭或改动云端 VAD / 静音阈值。
- 修改 `/voice/chat/ws` 对话编排（soft rearm 等）。
- 改成长/首页 UI 层拼接（前缀 `_textBeforeHold` 等保持）。
- 实现实时翻译产品本身。

## Decisions

### D1：累积落在 VoiceAsrWsClient

- **选择**：传输层统一累积；`CloudAsrHomeSpeechRecognizer` / UI 无感。
- **备选**：各 Feature 拼段 → 易再踩坑，否决。

### D2：状态机

```
beginUtterance:
  committed="", unstable="", commitSent=false
  _utteranceDone = Completer（仅 commit 后收束用）

asr_partial(t):
  unstable=t
  onPartial(join(committed, unstable))

asr_final(t)  [commitSent=false]:
  committed=join(committed, t); unstable=""
  onPartial(committed)
  // MUST NOT complete _utteranceDone

asr_final / asr_no_result [commitSent=true]:
  若有 text：committed=join(committed, text)
  complete(_utteranceDone, committed)

endUtterance:
  stop PCM; send commit; commitSent=true
  await _utteranceDone（既有超时）
  send end; 返回 committed.trim()
  （若 await 超时：仍返回已累积 committed，可并上残余 unstable）

cancelUtterance:
  清空状态；不返回正文
```

- **join**：中文场景直接拼接（无强制空格）；两端 trim 单段后再拼，避免重复空白失控。

### D3：与旧 Completer 行为差异

- 旧：`begin` 时创建 Completer，首个 `asr_final` complete。
- 新：中途 final **只**更新 `committed`；Completer **仅**在 `commitSent` 后由 final/no_result/timeout 完成。

### D4：全局规范

- 在 `openspec/project.md`「WebSocket 韧性传输」语音 ASR 例外下增加短条：段锁定语义、`VoiceAsrWsClient` MUST 累积、Feature/后续翻译 MUST NOT 平行只认首 final。
- 本条 **仅** 约束 `/voice/asr/ws`，不强制 chat WS 同构。

### D5：日志

- 若需排查分段，复用既有 debug 出口；新 tag 须三联改。默认可不加 tag，除非实现时需要。

## Risks / Trade-offs

- **[Risk] commit 后无第二段 final** → Mitigation：超时回退已 `committed`（+ unstable）。
- **[Risk] 段边界缺空格/标点** → Mitigation：先直接拼接；产品后续可调 join。
- **[Trade-off] chat WS 仍各自处理 final** → 文档写清分界，避免误改对话。

## Migration Plan

1. 改 `VoiceAsrWsClient` + `project.md` + spec。
2. 真机：按住 → 说 A → 停顿 → 说 B → 松手，预览与最终均为 A+B。
3. 回归首页云端按住发送指令。

## Open Questions

- （无）
