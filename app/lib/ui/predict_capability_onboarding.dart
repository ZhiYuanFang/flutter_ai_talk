import 'package:flutter/material.dart';

import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 预测 Pro 试用成功后的简短确认。
Future<void> showPredictBasicTrialSuccessDialog(
  BuildContext context, {
  required int days,
}) {
  return showGlassDialog<void>(
    context: context,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '体验已开通',
            style: TextStyle(
              color: glassText,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '预测能力 Pro 已开通约 $days 天。',
            style: TextStyle(color: glassLabel, height: 1.35),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('好的', style: TextStyle(color: scheme.primary)),
            ),
          ),
        ],
      );
    },
  );
}
