import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme_schedule.dart';
import '../theme/app_theme_scope.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_preset.dart';
import 'home_widget_payload.dart';

String colorToWidgetHex(Color c) {
  final v = c.toARGB32();
  return '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// 与 App 内 [buildAppTheme] 同源的小组件 visual tokens。
HomeWidgetVisualPayload buildHomeWidgetVisual({
  required BabySex sex,
  required ThemePreferences prefs,
}) {
  final bundle = resolveVisualBundle(sex: sex, seed: prefs.seed, preset: prefs.preset);
  final tokens = bundle.toTokens();
  final shell = tokens.shellColor;
  final surface = tokens.surfaceColor;
  final card = tokens.recordsCardColor;
  return HomeWidgetVisualPayload(
    shellGradientStart: colorToWidgetHex(shell),
    shellGradientEnd: colorToWidgetHex(Color.lerp(shell, surface, 0.55) ?? surface),
    glassFillTop: colorToWidgetHex(card),
    glassFillBottom: colorToWidgetHex(Color.lerp(card, surface, 0.25) ?? card),
    borderColor: colorToWidgetHex(tokens.surfaceBorderColor),
    textPrimary: colorToWidgetHex(tokens.onShell),
    textSecondary: colorToWidgetHex(tokens.onShell.withValues(alpha: 0.65)),
    shellOpacity: 0.7,
    isDarkShell: tokens.isDarkShell,
  );
}

HomeWidgetVisualPayload buildHomeWidgetVisualFromRef(dynamic ref) {
  final sex = ref.read(babySexProvider);
  final prefs = ref.read(effectiveThemeProvider);
  return buildHomeWidgetVisual(sex: sex, prefs: prefs);
}

bool themeVisualChanged(ThemePreferences? prev, ThemePreferences next, BabySex sex) {
  if (prev == null) return true;
  final a = buildHomeWidgetVisual(sex: sex, prefs: prev);
  final b = buildHomeWidgetVisual(sex: sex, prefs: next);
  return a.shellGradientStart != b.shellGradientStart ||
      a.shellGradientEnd != b.shellGradientEnd ||
      a.isDarkShell != b.isDarkShell;
}
