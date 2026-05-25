import 'package:flutter/material.dart';

import '../theme/app_visual_tokens.dart';

/// 历史区「回到底部」悬浮正圆按钮直径。
const kHomeHistoryScrollToBottomButtonSize = 28.0;

Color scrollToBottomButtonBorderColor(BuildContext context, Color primary) {
  final tokens = visualTokensOf(context);
  final isDark = tokens?.isDarkShell ?? Theme.of(context).brightness == Brightness.dark;
  if (tokens != null) {
    return Color.alphaBlend(primary.withValues(alpha: 0.55), tokens.pillBorder);
  }
  final hsl = HSLColor.fromColor(primary);
  return hsl
      .withLightness((hsl.lightness + (isDark ? -0.08 : -0.12)).clamp(0.0, 1.0))
      .toColor();
}

/// 非跟底时历史区底部正中悬浮的回到底部按钮。
class HomeHistoryScrollToBottomButton extends StatelessWidget {
  const HomeHistoryScrollToBottomButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fill = primary.withValues(alpha: 0.1);
    final borderColor = scrollToBottomButtonBorderColor(context, primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: kHomeHistoryScrollToBottomButtonSize,
          height: kHomeHistoryScrollToBottomButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: borderColor, width: 0.84),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.keyboard_arrow_down,
            size: 15,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
