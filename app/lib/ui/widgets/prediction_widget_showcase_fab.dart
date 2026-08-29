import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home_widget/has_pinned_home_widget.dart';

/// 预测竖屏底部：桌面小组件展示入口（横屏/Web 不挂载）。
class PredictionWidgetShowcaseFab extends ConsumerStatefulWidget {
  const PredictionWidgetShowcaseFab({super.key});

  /// 是否应在当前平台展示入口（不含朝向；朝向由调用方判断）。
  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  ConsumerState<PredictionWidgetShowcaseFab> createState() =>
      _PredictionWidgetShowcaseFabState();
}

class _PredictionWidgetShowcaseFabState
    extends ConsumerState<PredictionWidgetShowcaseFab>
    with WidgetsBindingObserver {
  var _pinned = false;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPinned());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPinned());
    }
  }

  Future<void> _refreshPinned() async {
    final pinned = await hasPinnedHomeWidget();
    if (!mounted) return;
    setState(() {
      _pinned = pinned;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = !_ready
        ? '桌面小组件'
        : (_pinned ? '查看桌面小组件' : '添加桌面小组件');
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/widgets/showcase'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                label,
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

/// 列表底部为 FAB 预留的额外高度。
double predictionWidgetShowcaseListBottomPad(BuildContext context) {
  if (!PredictionWidgetShowcaseFab.isPlatformSupported) return 0;
  return 72 + MediaQuery.paddingOf(context).bottom;
}
