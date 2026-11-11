import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

/// 合规标识字面量（展示用，不写回服务端）。
const kAiGeneratedMarkText = '（AI 生成）';

/// 合规标识固定红。
const kAiGeneratedMarkColor = Color(0xFFE53935);

/// Markdown 自定义 tag。
const kAiGeneratedMarkTag = 'ai_generated_mark';

/// 展示用文案末尾幂等追加「（AI 生成）」。
/// [asMarkdownBlock] 为 true 时用空行隔开，便于独立成段渲染。
String appendAiGeneratedMark(
  String source, {
  bool asMarkdownBlock = false,
}) {
  final t = source.trimRight();
  if (t.endsWith(kAiGeneratedMarkText)) return t;
  if (t.isEmpty) return kAiGeneratedMarkText;
  if (asMarkdownBlock) return '$t\n\n$kAiGeneratedMarkText';
  return '$t$kAiGeneratedMarkText';
}

/// 纯文本摘要：正文 + 红色小字尾标（同一 Text.rich 流）。
Widget aiGeneratedMarkedPlainText({
  required String text,
  required TextStyle style,
  int? maxLines,
  TextOverflow? overflow,
}) {
  // 去掉已有尾标再拼，避免重复。
  var body = text.trimRight();
  if (body.endsWith(kAiGeneratedMarkText)) {
    body = body.substring(0, body.length - kAiGeneratedMarkText.length);
  }
  final markStyle = style.copyWith(
    color: kAiGeneratedMarkColor,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        TextSpan(text: body),
        TextSpan(text: kAiGeneratedMarkText, style: markStyle),
      ],
    ),
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
  );
}

/// 匹配字面量「（AI 生成）」→ 自定义 tag。
class AiGeneratedMarkSyntax extends m.InlineSyntax {
  AiGeneratedMarkSyntax() : super(kAiGeneratedMarkText);

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    parser.addNode(m.Element.text(kAiGeneratedMarkTag, kAiGeneratedMarkText));
    return true;
  }
}

/// 红小字 Span。
class AiGeneratedMarkNode extends SpanNode {
  @override
  InlineSpan build() {
    final base = parentStyle ?? const TextStyle();
    return TextSpan(
      text: kAiGeneratedMarkText,
      style: base.merge(
        const TextStyle(
          color: kAiGeneratedMarkColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

/// markdown_widget 生成器。
final aiGeneratedMarkGenerator = SpanNodeGeneratorWithTag(
  tag: kAiGeneratedMarkTag,
  generator: (e, config, visitor) => AiGeneratedMarkNode(),
);

/// 带合规尾标解析的 MarkdownGenerator。
MarkdownGenerator aiGeneratedMarkdownGenerator({
  EdgeInsets linesMargin = const EdgeInsets.symmetric(vertical: 4),
}) {
  return MarkdownGenerator(
    linesMargin: linesMargin,
    inlineSyntaxList: [AiGeneratedMarkSyntax()],
    generators: [aiGeneratedMarkGenerator],
  );
}
