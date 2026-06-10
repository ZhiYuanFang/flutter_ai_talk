import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_scope.dart';
import 'custom_background_persist.dart';
import 'theme_preset.dart';

/// 19:00–05:00 夜空（可关闭）；其余时段用户基线主题。
class AppThemeSchedule {
  AppThemeSchedule._();

  static bool isNightWindow(DateTime now) {
    final h = now.hour;
    return h >= 19 || h < 5;
  }

  static ThemePreferences resolveDisplay(
    DateTime now,
    ThemePreferences baseline, {
    required bool scheduleEnabled,
  }) {
    if (scheduleEnabled && isNightWindow(now)) {
      return ThemePreferences(
        seed: kNightSkyShell,
        preset: ThemePreset.nightSky,
        scheduleEnabled: baseline.scheduleEnabled,
      );
    }
    return baseline;
  }
}

/// 按当前时间与基线 provider 计算生效主题。
final effectiveThemeProvider = Provider<ThemePreferences>((ref) {
  ref.watch(themeScheduleTickProvider);
  final baseline = ThemePreferences(
    seed: ref.watch(customBackgroundProvider),
    preset: ref.watch(themePresetProvider),
    scheduleEnabled: ref.watch(themeScheduleEnabledProvider),
  );
  return AppThemeSchedule.resolveDisplay(
    DateTime.now(),
    baseline,
    scheduleEnabled: baseline.scheduleEnabled,
  );
});

void refreshScheduledTheme(WidgetRef ref) {
  ref.read(themeScheduleTickProvider.notifier).state++;
}

/// 冷启动：从磁盘加载用户基线到 Riverpod（含 soft preset 迁移）。
Future<void> applyUserThemeBaseline(WidgetRef ref) async {
  final baseline = await loadThemePreferences();
  ref.read(themePresetProvider.notifier).state = baseline.preset;
  ref.read(customBackgroundProvider.notifier).state = baseline.seed;
  ref.read(themeScheduleEnabledProvider.notifier).state = baseline.scheduleEnabled;
  refreshScheduledTheme(ref);
}

@Deprecated('Use applyUserThemeBaseline')
Future<void> applyScheduledThemeOnColdStart(WidgetRef ref) => applyUserThemeBaseline(ref);
