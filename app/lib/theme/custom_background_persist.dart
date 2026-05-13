import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCustomBgColorKey = 'custom_bg_color';

Future<void> persistCustomBackground(Color? color) async {
  final prefs = await SharedPreferences.getInstance();
  if (color == null) {
    await prefs.remove(_kCustomBgColorKey);
  } else {
    await prefs.setInt(_kCustomBgColorKey, color.value);
  }
}

Future<Color?> loadCustomBackground() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getInt(_kCustomBgColorKey);
  if (v == null) return null;
  return Color(v);
}
