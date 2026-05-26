import 'package:flutter/material.dart';

import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 展示 [sendCommand] 返回的完整服务端回复。
Future<void> showHomeReplyBottomSheet(BuildContext context, String reply) {
  return showGlassAdaptiveBottomSheet<void>(
    context: context,
    bodyBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '服务端回复',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: glassText),
          ),
          const SizedBox(height: 12),
          SelectableText(
            reply,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: glassLabel),
          ),
        ],
      );
    },
  );
}
