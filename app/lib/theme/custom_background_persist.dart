import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preset.dart';

const _kCustomBgColorKey = 'custom_bg_color';
const _kThemePresetIdKey = 'theme_preset_id';
const _kThemeScheduleEnabledKey = 'theme_schedule_enabled';

class ThemePreferences {
  const ThemePreferences({
    this.seed,
    this.preset,
    this.scheduleEnabled = true,
  });

  final Color? seed;
  final ThemePreset? preset;
  final bool scheduleEnabled;
}

/// 兼容旧 API。
Future<void> persistCustomBackground(Color? color) async {
  await persistThemePreferences(seed: color, preset: null);
}

Future<Color?> loadCustomBackground() async {
  final prefs = await loadThemePreferences();
  return prefs.seed;
}

Future<ThemePreferences> loadThemePreferences() async {
  final sp = await SharedPreferences.getInstance();
  final scheduleEnabled = sp.getBool(_kThemeScheduleEnabledKey) ?? true;
  var preset = ThemePreset.fromId(sp.getString(_kThemePresetIdKey));
  final raw = sp.getInt(_kCustomBgColorKey);
  if (preset != null && isSoftSwatchThemePreset(preset)) {
    final seed = swatchColorForThemePreset(preset);
    final migrated = ThemePreferences(seed: seed, preset: null, scheduleEnabled: scheduleEnabled);
    await persistThemePreferences(seed: seed, preset: null, scheduleEnabled: scheduleEnabled);
    return migrated;
  }
  if (raw == null) {
    return ThemePreferences(seed: null, preset: preset, scheduleEnabled: scheduleEnabled);
  }
  final color = Color(raw);
  if (color.value == kLegacyPureBlack.value) {
    final migrated = ThemePreferences(
      seed: kNightSkyShell,
      preset: ThemePreset.nightSky,
      scheduleEnabled: scheduleEnabled,
    );
    await persistThemePreferences(
      seed: kNightSkyShell,
      preset: ThemePreset.nightSky,
      scheduleEnabled: scheduleEnabled,
    );
    return migrated;
  }
  return ThemePreferences(seed: color, preset: preset, scheduleEnabled: scheduleEnabled);
}

Future<void> persistThemePreferences({
  Color? seed,
  ThemePreset? preset,
  bool? scheduleEnabled,
}) async {
  final sp = await SharedPreferences.getInstance();
  if (seed == null) {
    await sp.remove(_kCustomBgColorKey);
  } else {
    await sp.setInt(_kCustomBgColorKey, seed.value);
  }
  if (preset == null) {
    await sp.remove(_kThemePresetIdKey);
  } else {
    await sp.setString(_kThemePresetIdKey, preset.id);
  }
  if (scheduleEnabled != null) {
    await sp.setBool(_kThemeScheduleEnabledKey, scheduleEnabled);
  }
}

Future<void> clearThemePreferences() async {
  final sp = await SharedPreferences.getInstance();
  final scheduleEnabled = sp.getBool(_kThemeScheduleEnabledKey) ?? true;
  await persistThemePreferences(seed: null, preset: null, scheduleEnabled: scheduleEnabled);
}
