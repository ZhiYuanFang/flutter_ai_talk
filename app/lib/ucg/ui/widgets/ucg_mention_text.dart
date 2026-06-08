/// @提及 wire（`@昵称#wxId`）与展示文案（`@昵称`）互转。
class UcgMentionText {
  UcgMentionText._();

  static final wirePattern = RegExp(r'@([^\s@]+?)#(\d+)(\s?)');

  /// 评论/通知展示：去掉 `#wxId` 后缀。
  static String displayComment(String text) {
    return text.replaceAllMapped(
      RegExp(r'@([^\s@]+?)#\d+'),
      (m) => '@${m.group(1)}',
    );
  }

  /// 解析开头预填的 wire mention → 展示文本 + 元数据。
  static ({String display, String? nick, String? wxId}) parseLeadingMention(String? wire) {
    if (wire == null || wire.isEmpty) {
      return (display: '', nick: null, wxId: null);
    }
    final match = wirePattern.firstMatch(wire);
    if (match == null || match.start != 0) {
      return (display: wire, nick: null, wxId: null);
    }
    final nick = match.group(1) ?? '';
    final wxId = match.group(2) ?? '';
    final tail = match.group(3) ?? ' ';
    final display = '@$nick$tail${wire.substring(match.end)}';
    return (display: display, nick: nick, wxId: wxId);
  }

  /// 发送前：将展示层开头 `@昵称 ` 还原为 wire `@昵称#wxId `。
  /// 若 [selfWxId] 与 mention 相同则 strip @，不允许 @ 自己。
  static String toWire(
    String display, {
    String? nick,
    String? wxId,
    String? selfWxId,
  }) {
    if (nick == null || nick.isEmpty || wxId == null || wxId.isEmpty) {
      return display;
    }
    final prefix = '@$nick ';
    if (!display.startsWith(prefix)) return display;
    final rest = display.substring(prefix.length);
    if (selfWxId != null && selfWxId.isNotEmpty && wxId == selfWxId) {
      return rest;
    }
    return '@$nick#$wxId $rest';
  }
}
