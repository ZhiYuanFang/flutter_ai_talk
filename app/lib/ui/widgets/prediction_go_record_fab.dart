import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_pager.dart';

/// 预测竖屏底部：「去记录」入口（视觉对齐已删的桌面小组件 pill FAB）。
class PredictionGoRecordFab extends ConsumerWidget {
  const PredictionGoRecordFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 主题主容器色：与旧 showcase FAB 一致
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        // 经主壳 pager 切到喂养页（不 push 重复路由）
        onTap: () {
          ref
              .read(homePagerRequestProvider.notifier)
              .requestPage(HomePagerPage.feeding);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '去记录',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
