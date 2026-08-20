import 'package:flutter/material.dart';

import '../config/trends_date_range_store.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 底部 Sheet 选择趋势范围预设（近7日 / 近15日 / 近1个月）。
Future<TrendsRangePreset?> showTrendsRangePresetGlassSheet(
  BuildContext context, {
  required TrendsRangePreset initial,
  Color? eventAccent,
}) {
  return showGlassAdaptiveBottomSheet<TrendsRangePreset>(
    context: context,
    maxHeightFraction: 0.45,
    enableDrag: true,
    eventAccent: eventAccent,
    scrollable: false,
    bodyBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final accent = eventAccent ?? scheme.primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '选择时间范围',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: glassText),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          Expanded(
            child: ListView(
              children: [
                for (final p in TrendsRangePreset.values)
                  ListTile(
                    selected: p == initial,
                    title: Text(p.label, style: TextStyle(color: glassText)),
                    trailing: p == initial
                        ? Icon(Icons.check, color: accent)
                        : null,
                    onTap: () => Navigator.pop(ctx, p),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
