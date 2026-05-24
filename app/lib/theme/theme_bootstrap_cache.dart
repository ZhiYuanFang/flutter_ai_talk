import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

const _kCachedBabySexKey = 'cached_baby_sex';

Future<void> persistCachedBabySex(BabySex sex) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kCachedBabySexKey, sex.name);
}

Future<BabySex?> loadCachedBabySex() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kCachedBabySexKey);
  if (raw == null) return null;
  return switch (raw) {
    'male' => BabySex.male,
    'female' => BabySex.female,
    'unknown' => BabySex.unknown,
    _ => null,
  };
}
