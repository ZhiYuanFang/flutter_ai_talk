import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ucg_location.dart';

/// 广场 Tab：GPS 关或 App 权限未开时的轻提示横幅。
class UcgLocationSettingsHint extends ConsumerWidget {
  const UcgLocationSettingsHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(ucgLocationHintKindProvider);
    if (kind == UcgLocationHintKind.none) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final message = switch (kind) {
      UcgLocationHintKind.gpsServiceOff => '请先开启手机定位，以便展示动态距离',
      UcgLocationHintKind.appPermissionDenied => '允许位置权限后可展示动态距离',
      UcgLocationHintKind.none => '',
    };
    final actionLabel = switch (kind) {
      UcgLocationHintKind.gpsServiceOff => '开启定位',
      UcgLocationHintKind.appPermissionDenied => '去设置',
      UcgLocationHintKind.none => '',
    };
    final onAction = switch (kind) {
      UcgLocationHintKind.gpsServiceOff => openUcgLocationServiceSettings,
      UcgLocationHintKind.appPermissionDenied => openUcgAppLocationSettings,
      UcgLocationHintKind.none => null,
    };

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
