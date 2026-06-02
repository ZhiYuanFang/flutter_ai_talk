/// 首页输入模式（语音 / 文字 / 按钮）。
/// 移动端 UI 仅暴露语音与按钮；`text` 保留供 Web 与历史持久化键兼容。
enum HomeInputChannel { voice, text, buttons }
