import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_widget/home_widget_sync.dart';
import '../theme/app_color.dart';
import '../theme/app_theme_schedule.dart';
import '../theme/app_theme_scope.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_custom_color_wheel.dart';
import '../theme/theme_preset.dart';
import 'widgets/app_glass_overlay.dart';

/// 主壳顶栏调色盘：打开公用主题 Sheet。
class ThemePaletteIconButton extends ConsumerWidget {
  const ThemePaletteIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = AppColor.textPrimary(context);
    return IconButton(
      tooltip: '主题',
      icon: Icon(Icons.palette_outlined, color: fg),
      onPressed: () => unawaited(showThemePaletteSheet(context)),
    );
  }
}

/// 三页共用的主题调色底部 Sheet。
Future<void> showThemePaletteSheet(BuildContext context) {
  return showGlassAdaptiveBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.85,
    respectKeyboardInset: true,
    bodyBuilder: (ctx) => const _ThemePaletteSheetBody(),
  );
}

class _ThemePaletteSheetBody extends ConsumerWidget {
  const _ThemePaletteSheetBody();

  static const _classicSwatch = Color(0xFFF5F5F5);
  static const _defaultCustomPreview = Color(0xFFE3F2FD);

  Future<void> _applyBaseline(
    WidgetRef ref, {
    ThemePreset? preset,
    Color? seed,
  }) async {
    await persistThemePreferences(seed: seed, preset: preset);
    ref.read(themePresetProvider.notifier).state = preset;
    ref.read(customBackgroundProvider.notifier).state = seed;
    refreshScheduledTheme(ref);
    unawaited(scheduleHomeWidgetSync(ref));
  }

  Future<void> _clearToClassic(WidgetRef ref) async {
    await clearThemePreferences();
    ref.read(themePresetProvider.notifier).state = null;
    ref.read(customBackgroundProvider.notifier).state = null;
    refreshScheduledTheme(ref);
    unawaited(scheduleHomeWidgetSync(ref));
  }

  Future<void> _setScheduleEnabled(WidgetRef ref, bool enabled) async {
    await persistThemePreferences(scheduleEnabled: enabled);
    ref.read(themeScheduleEnabledProvider.notifier).state = enabled;
    refreshScheduledTheme(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSheet = AppColor.textOnSheet(context);
    final scheduleEnabled = ref.watch(themeScheduleEnabledProvider);
    final baselinePreset = ref.watch(themePresetProvider);
    final baselineSeed = ref.watch(customBackgroundProvider);
    final isClassic = baselinePreset == null && baselineSeed == null;
    final isNightBaseline = baselinePreset == ThemePreset.nightSky;
    final isCustom = baselinePreset == null && baselineSeed != null;
    final previewColor = baselineSeed ?? _defaultCustomPreview;
    final canPickCustom = !scheduleEnabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '主题',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: onSheet,
                ),
              ),
              const Spacer(),
              // 标题 + 调度窗口小字（始终显示，与 AppThemeSchedule 19:00–05:00 一致）
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '自动入夜',
                    style: TextStyle(
                      fontSize: 13,
                      color: onSheet.withValues(alpha: 0.75),
                    ),
                  ),
                  Text(
                    '19:00–05:00',
                    style: TextStyle(
                      fontSize: 11,
                      color: onSheet.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: scheduleEnabled,
                onChanged: (v) => unawaited(_setScheduleEnabled(ref, v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetSwatch(
                label: '经典',
                color: _classicSwatch,
                selected: isClassic,
                onTap: () => unawaited(_clearToClassic(ref)),
              ),
              _PresetSwatch(
                label: '夜空',
                color: kNightSkyShell,
                selected: isNightBaseline,
                onTap: () => unawaited(
                  _applyBaseline(
                    ref,
                    preset: ThemePreset.nightSky,
                    seed: kNightSkyShell,
                  ),
                ),
              ),
              if (canPickCustom)
                _ColorfulSwatch(
                  label: '彩色',
                  seed: baselineSeed,
                  selected: isCustom,
                  // 色盘已默认展示；点彩色仅提示选中态（改色会自动选中）
                  onTap: () {
                    if (baselineSeed != null) {
                      unawaited(
                        _applyBaseline(ref, preset: null, seed: baselineSeed),
                      );
                    }
                  },
                ),
            ],
          ),
          if (canPickCustom) ...[
            const SizedBox(height: 12),
            _CustomThemeColorPicker(
              color: previewColor,
              selected: isCustom,
              onColorChanged: (c) => unawaited(
                _applyBaseline(ref, preset: null, seed: c),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '自动夜空开启时不可自定义颜色',
              style: TextStyle(
                fontSize: 12,
                color: onSheet.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorfulSwatch extends StatelessWidget {
  const _ColorfulSwatch({
    required this.label,
    required this.seed,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color? seed;
  final bool selected;
  final VoidCallback onTap;

  static const _rainbow = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.black26;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: selected ? 2.5 : 1,
              ),
              color: seed,
              gradient: seed == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _rainbow,
                    )
                  : null,
            ),
            child: seed == null
                ? Icon(
                    Icons.palette_outlined,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 22,
                  )
                : (selected
                    ? Icon(
                        Icons.check,
                        color: seed!.computeLuminance() < 0.4
                            ? Colors.white
                            : Colors.black87,
                        size: 20,
                      )
                    : null),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CustomThemeColorPicker extends StatelessWidget {
  const _CustomThemeColorPicker({
    required this.color,
    required this.selected,
    required this.onColorChanged,
  });

  final Color color;
  final bool selected;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ThemeCustomColorWheel(
          color: color,
          onColorChanged: onColorChanged,
        ),
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : (color.computeLuminance() < 0.15 ? Colors.white38 : Colors.black26);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() < 0.4
                        ? Colors.white
                        : Colors.black87,
                    size: 20,
                  )
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
