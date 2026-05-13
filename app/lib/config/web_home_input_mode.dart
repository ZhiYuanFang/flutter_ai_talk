/// Web 端主页主输入模式（仅 `kIsWeb` 时由 [resolveWebHomeInputMode] 消费）。
enum WebHomeInputMode {
  text,
  voice,
}

/// 未传入 `--dart-define=WEB_HOME_INPUT=...` 时的默认模式。
/// 修改此常量可将仓库默认改为语音主输入（仍可用构建参数覆盖）。
const WebHomeInputMode kDefaultWebHomeInputMode = WebHomeInputMode.text;

/// 单一解析入口：优先 `WEB_HOME_INPUT`，否则 [kDefaultWebHomeInputMode]。
///
/// 构建示例：`flutter run -d chrome --dart-define=WEB_HOME_INPUT=voice`
WebHomeInputMode resolveWebHomeInputMode() {
  const env = String.fromEnvironment('WEB_HOME_INPUT', defaultValue: '');
  if (env.isEmpty) return kDefaultWebHomeInputMode;
  switch (env.toLowerCase()) {
    case 'voice':
    case 'speech':
      return WebHomeInputMode.voice;
    case 'text':
    default:
      return WebHomeInputMode.text;
  }
}
