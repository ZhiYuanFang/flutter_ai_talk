/// 流式思考增量：以 `\r` 为阶段边界，清空后再写，避免长文累计。
///
/// - 遇 `\r`：当前缓冲清空
/// - `\r` 后紧跟 `\n`：跳过该 `\n`（兼容 `\r\n`）
/// - 单独 `\n`：当作普通字符保留
String applyThinkingStageDelta(String previous, String delta) {
  if (delta.isEmpty) return previous;
  final out = StringBuffer(previous);
  var i = 0;
  while (i < delta.length) {
    final ch = delta[i];
    if (ch == '\r') {
      out.clear();
      i++;
      // 清屏后跳过紧跟的 LF，避免新阶段以空行开头。
      if (i < delta.length && delta[i] == '\n') {
        i++;
      }
      continue;
    }
    out.write(ch);
    i++;
  }
  return out.toString();
}
