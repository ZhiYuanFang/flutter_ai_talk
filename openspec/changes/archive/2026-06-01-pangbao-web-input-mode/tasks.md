## 1. 配置与文档

- [x] 1.1 新增单一来源的 Web 主输入模式配置（顶层常量或 `dart-define` + 小函数，默认文本），并在 `app/README.md` 中说明如何切换
- [x] 1.2 确认命名与导出位置，避免与路由、环境变量命名冲突

## 2. 主页行为

- [x] 2.1 在 `HomeScreen` 中：当 `kIsWeb` 且配置为语音模式时，初始化语音识别（沿用 `speech_to_text` 或按 design 落备选方案），并复用与移动端一致的按住说话 UI 与 `_onVoiceEnd` 提交流
- [x] 2.2 当 `kIsWeb` 且配置为文本模式时，保持现有 `_buildWebInput` 与提交逻辑不变
- [x] 2.3 当 `kIsWeb` 且语音模式但初始化失败时，降级为文本输入并给出可见或日志提示，且仍可发送指令

## 3. 验证

- [x] 3.1 `dart analyze`（或 `flutter analyze`）无新增错误
- [x] 3.2 手动验证：默认配置下 Web 仍为文本；开启语音配置后 Chrome 至少一条识别路径可用（或记录已知限制到 README）
