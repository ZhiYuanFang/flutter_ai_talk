import 'package:flutter/material.dart';

import '../../scaffold_messenger_key.dart';
import '../../theme/app_visual_tokens.dart';

enum AppToastTone {
  info,
  success,
  error,
}

/// 屏幕正中、圆角雾面、短停留的全局轻提示。
void showAppToast(
  String message, {
  AppToastTone tone = AppToastTone.info,
  ScaffoldMessengerState? messenger,
}) {
  if (message.trim().isEmpty) return;
  final m = messenger ?? appScaffoldMessengerKey.currentState;
  if (m == null) return;

  final ctx = m.context;
  final media = MediaQuery.of(ctx);
  const estimatedHeight = 44.0;
  final bottomMargin = ((media.size.height - estimatedHeight) / 2).clamp(0.0, double.infinity);

  final duration = switch (tone) {
    AppToastTone.error => const Duration(seconds: 2),
    AppToastTone.info || AppToastTone.success => const Duration(seconds: 1),
  };

  m.clearSnackBars();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: duration,
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomMargin,
      ),
      content: _AppToastContent(message: message),
    ),
  );
}

class _AppToastContent extends StatelessWidget {
  const _AppToastContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final shell = tokens?.shellColor ?? Theme.of(context).colorScheme.surface;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(onShell.withValues(alpha: 0.1), shell),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onShell.withValues(alpha: 0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onShell.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: shell.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
