import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';

/// 登录后由业务写入，用于全局主题默认色。
final babySexProvider = StateProvider<BabySex>((ref) => BabySex.unknown);

final customBackgroundProvider = StateProvider<Color?>((ref) => null);

Color _sexPrimary(BabySex sex) {
  switch (sex) {
    case BabySex.male:
      return const Color(0xFF0D47A1);
    case BabySex.female:
      return const Color(0xFFC62828);
    case BabySex.unknown:
      return const Color(0xFF455A64);
  }
}

ThemeData buildAppTheme({
  required BabySex sex,
  Color? customBackground,
}) {
  final primary = _sexPrimary(sex);
  final bg = customBackground ?? Color.alphaBlend(primary.withValues(alpha: 0.08), Colors.white);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: Color.alphaBlend(primary.withValues(alpha: 0.12), Colors.white),
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
