## 1. VoiceAsrWsClient 句段累积

- [x] 1.1 在 `VoiceAsrWsClient` 实现 `committed` / `unstable` / `commitSent`；中途 `asr_final` 只追加锁定段，不 complete 整轮
- [x] 1.2 `onPartial` 上送 `join(committed, unstable)` 全文；`endUtterance` 在 `commit` 后 await 收束并返回累积全文（超时回退已累积）
- [x] 1.3 `cancelUtterance` / 断连清理本轮累积状态

## 2. 全局规范

- [x] 2.1 在 `openspec/project.md` 语音 ASR 例外旁写入：静音 `asr_final` 为段锁定、整轮边界仅 commit/end/cancel、`VoiceAsrWsClient` MUST 累积、Feature/后续翻译 MUST NOT 平行「只认首 final」

## 3. 服务端会话全文（go_ai_talk）

- [x] 3.1 `voice_asr_ws.go`：`sessionCommitted`/`sessionUnstable`；partial/final 下行会话全文；业务 asr_final 仍仅 commit/end
- [x] 3.2 Flutter：信任下行全文 + 旧服兜底拼段；成长/首页/伴侣松手 `preferRicherTranscript`

## 4. 验收

- [ ] 4.1 部署听写 WS 后真机：按住 → 说 A → 停顿 → 说 B → 松手；预览与最终均为 A+B
- [x] 4.2 对照情景走查；确认未改 `/voice/chat/ws` 编排
