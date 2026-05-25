import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preset.dart';

const _kCustomBgColorKey = 'custom_bg_color';
const _kThemePresetIdKey = 'theme_preset_id';

class ThemePreferences {
  const ThemePreferences({this.seed, this.preset});

  final Color? seed;
  final ThemePreset? preset;
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
  final preset = ThemePreset.fromId(sp.getString(_kThemePresetIdKey));
  final raw = sp.getInt(_kCustomBgColorKey);
  if (raw == null) {
    return ThemePreferences(seed: null, preset: preset);
  }
  final color = Color(raw);
  if (color.value == kLegacyPureBlack.value) {
    final migrated = ThemePreferences(seed: kNightSkyShell, preset: ThemePreset.nightSky);
    await persistThemePreferences(seed: kNightSkyShell, preset: ThemePreset.nightSky);
    return migrated;
  }
  return ThemePreferences(seed: color, preset: preset);
}

Future<void> persistThemePreferences({Color? seed, ThemePreset? preset}) async {
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
}

Future<void> clearThemePreferences() async {
  await persistThemePreferences(seed: null, preset: null);
}
