import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// 胖宝诊疗助手答案：流式阶段纯文本，完成后 Markdown 格式化。
class ClinicAnswerBody extends StatelessWidget {
  const ClinicAnswerBody({
    super.key,
    required this.text,
    required this.streaming,
    /// tip 等场景关选区，避免抢走外层 tap
    this.selectable = true,
    /// false 时由外层 ScrollView 负责滚动（shrinkWrap + NeverScrollable）
    this.scrollable = false,
  });

  final String text;
  final bool streaming;
  final bool selectable;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (streaming) {
      // 流式纯文本；外层若有 SelectionArea 则可顺带选中
      return Text(text, style: _bodyStyle(context));
    }
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final generator = MarkdownGenerator(
      linesMargin: const EdgeInsets.symmetric(vertical: 4),
    );
    final config = _markdownConfig(context);
    // 气泡内用 Column（MarkdownBlock），避免 MarkdownWidget 内层 ListView 与外层列表抢拖动手势
    if (!scrollable) {
      return MarkdownBlock(
        data: text,
        selectable: selectable,
        config: config,
        generator: generator,
      );
    }
    return MarkdownWidget(
      data: text,
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      selectable: selectable,
      config: config,
      markdownGenerator: generator,
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle(height: 1.45);
  }

  MarkdownConfig _markdownConfig(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final body = _bodyStyle(context);
    final titleMedium = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.35,
        ) ??
        body.copyWith(fontWeight: FontWeight.w600, fontSize: 16);
    final titleSmall = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.35,
        ) ??
        body.copyWith(fontWeight: FontWeight.w600);
    final h3Style = titleSmall.copyWith(
      fontSize: (titleSmall.fontSize ?? 14),
    );
    final codeBg = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
      scheme.surfaceContainerHighest,
    );

    return MarkdownConfig(configs: [
      PConfig(textStyle: body),
      _ClinicHeadingConfig(MarkdownTag.h1.name, titleMedium),
      _ClinicHeadingConfig(MarkdownTag.h2.name, titleSmall),
      _ClinicHeadingConfig(MarkdownTag.h3.name, h3Style),
      _ClinicHeadingConfig(MarkdownTag.h4.name, body.copyWith(fontWeight: FontWeight.w600)),
      _ClinicHeadingConfig(MarkdownTag.h5.name, body.copyWith(fontWeight: FontWeight.w600)),
      _ClinicHeadingConfig(MarkdownTag.h6.name, body.copyWith(fontWeight: FontWeight.w600)),
      HrConfig(height: 1, color: scheme.outlineVariant),
      LinkConfig(
        style: body.copyWith(decoration: TextDecoration.none, color: onSurface),
        onTap: (_) {},
      ),
      const ListConfig(marginLeft: 20, marginBottom: 4),
      CodeConfig(style: body.copyWith(backgroundColor: codeBg)),
      PreConfig(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        textStyle: body.copyWith(fontFamily: 'monospace', fontSize: 13),
        decoration: BoxDecoration(
          color: codeBg,
          borderRadius: BorderRadius.circular(6),
        ),
        theme: const {},
      ),
      ImgConfig(
        builder: (url, attributes) {
          final alt = (attributes['alt'] ?? '').trim();
          return Text(alt.isNotEmpty ? alt : url, style: body);
        },
      ),
    ]);
  }
}

class _ClinicHeadingConfig extends HeadingConfig {
  const _ClinicHeadingConfig(this.headingTag, this.style);

  final String headingTag;

  @override
  final TextStyle style;

  @override
  String get tag => headingTag;
}
