## 1. 共享工具

- [x] 1.1 新增 `applyThinkingStageDelta(previous, delta)`：`\r` 清缓冲；跳过 `\r` 后紧跟的 `\n`；单独 `\n` 保留
- [x] 1.2 文件放在 `app/lib/util/thinking_stage_delta.dart`（或等价纯 Dart 路径）

## 2. 接入展示面

- [x] 2.1 `landscape_voice_provider`：`VoiceChatThinkingDelta` 改用该函数更新 `thinking` 与字幕
- [x] 2.2 `pangbao_ai_screen`：`thinking_delta` 累加改用该函数

## 3. 验收

- [ ] 3.1 横屏：思考弹幕按阶段短句切换，不堆长文
- [ ] 3.2 陪伴：思考气泡/折叠区同样按 `\r` 分段
