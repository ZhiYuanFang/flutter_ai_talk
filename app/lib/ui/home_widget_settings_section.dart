import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/baby_age.dart';
import '../data/event_next_predictor.dart';
import '../home_widget/home_widget_sync.dart';
import '../providers/settings_baby.dart';
import '../theme/app_color.dart';

/// 设置页：桌面小组件预览与引导。
class HomeWidgetSettingsSection extends ConsumerStatefulWidget {
  const HomeWidgetSettingsSection({super.key});

  @override
  ConsumerState<HomeWidgetSettingsSection> createState() =>
      _HomeWidgetSettingsSectionState();
}

class _HomeWidgetSettingsSectionState
    extends ConsumerState<HomeWidgetSettingsSection> {
  var _preparing = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    final babyAsync = ref.watch(settingsBabyProvider);
    // 与预测页 / native sync 同源：真历史 ∪ 间隔旁路
    final inputs = resolveWidgetPredictionInputs(ref);

    return babyAsync.when(
      data: (baby) {
        final catalog = inputs.catalog;
        final history = inputs.history;
        final now = DateTime.now();
        final disabled = inputs.disabledForecastIds;
        final enabledActive = {
          for (final k in inputs.activeEventKeys)
            if (!disabled.contains(k)) k,
        };
        final preds = predictAllUpcoming(
          history: history,
          catalog: catalog,
          now: now,
          birthDate: baby.birthDate,
          activeEventKeys: enabledActive,
          recallIntervalsByRoot: {
            for (final e in inputs.recallIntervalsByRoot.entries)
              if (!disabled.contains(e.key)) e.key: e.value,
          },
        );
        final active = collectActiveTimingRows(history, catalog: catalog);
        final rows = buildWidgetRows(
          history: history,
          catalog: catalog,
          predictions: preds,
          kind: HomeWidgetKind.medium,
          now: now,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '桌面小组件',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '在系统桌面添加「胖宝」小组件（小/中/大），展示即将发生的喂养事件。首次添加会后台准备历史数据。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.textMuted(context),
                  ),
            ),
            const SizedBox(height: 10),
            if (baby.id.isNotEmpty)
              Text(
                formatWidgetHeaderLine(baby, now),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(
                active.isEmpty && preds.isEmpty
                    ? HomeWidgetConstants.emptyMessage
                    : HomeWidgetConstants.loadingMessage,
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...rows.map((row) {
                final subtitle = row.kind == 'recent'
                    ? formatWidgetLastAt(
                        row.lastAt != null
                            ? DateTime.tryParse(row.lastAt!)
                            : null,
                        now,
                      )
                    : formatWidgetPredictSubtitle(
                        DateTime.parse(row.nextAt!),
                        now,
                        overdue: row.status == 'overdue',
                      );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 28,
                        color: _parseColor(row.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _preparing
                  ? null
                  : () async {
                      setState(() => _preparing = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ensureWidgetReadyFromRef(ref);
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('小组件数据已更新')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _preparing = false);
                      }
                    },
              child: Text(_preparing ? '准备中…' : '刷新小组件数据'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _parseColor(String hex) {
    var s = hex.replaceFirst('#', '');
    if (s.length == 8) s = s.substring(2);
    final v = int.tryParse(s, radix: 16) ?? 0x5BA3E8;
    return Color(0xFF000000 | v);
  }
}
