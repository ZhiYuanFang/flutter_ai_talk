import 'package:flutter/material.dart';

/// 主页主输入区统一字幕框：固定高度，转写与服务端回复覆盖展示。
class HomeInputCaption extends StatelessWidget {
  const HomeInputCaption({
    super.key,
    required this.text,
    this.expandable = false,
    this.onExpand,
  });

  /// 为 null 或空时仅占位，不显示文字。
  final String? text;

  /// 为 true 且文本被截断时，可点击 [onExpand]（仅服务端回复场景）。
  final bool expandable;

  final VoidCallback? onExpand;

  static const double slotHeight = 52;
  static const double slotWidth = 280;

  static TextStyle captionStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.25,
        );
  }

  static bool textExceedsPreviewLines(String text, double width, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 3,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final t = text?.trim();
    if (t == null || t.isEmpty) {
      return const SizedBox(width: slotWidth, height: slotHeight);
    }

    final style = captionStyle(context);
    final canExpand = expandable && onExpand != null;

    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final truncated = textExceedsPreviewLines(t, constraints.maxWidth, style);
          final tappable = canExpand && truncated;

          final preview = Text(
            t,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style,
          );

          if (!tappable) {
            return Center(child: preview);
          }

          final scheme = Theme.of(context).colorScheme;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    preview,
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
