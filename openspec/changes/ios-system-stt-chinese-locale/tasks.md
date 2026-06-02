## 1. 中文 locale 解析

- [x] 1.1 在 `system_stt_home_speech_recognizer.dart` 新增私有方法，从 `speech_to_text.locales()` 按 design 优先级（`zh_CN`/`zh-CN` → `cmn-Hans-CN` → `zh`/`cmn-Hans` 前缀）选取 `localeId`，无匹配时 fallback `'zh_CN'`
- [x] 1.2 在 `prepare()` 成功初始化后调用上述方法并缓存到实例字段（如 `_chineseLocaleId`）

## 2. listen 传参

- [x] 2.1 在 `startSession()` 的 `_speech.listen()` 调用中传入 `localeId: _chineseLocaleId`（或 prepare 未完成时的 `'zh_CN'` fallback）
- [x] 2.2 确认 `SpeechListenOptions`（`dictation`、`cancelOnError`）行为与改动前一致

## 3. 验证

- [ ] 3.1 在 iOS 真机（系统语言可设为英文）选择「系统识别」，按住说话说中文，确认转写为中文
- [ ] 3.2 确认识别失败时仍可文字输入/切换云端识别，无崩溃（对应 spec「设备无中文听写包时不崩溃」）
