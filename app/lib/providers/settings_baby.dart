import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'repositories.dart';

final settingsBabyProvider = FutureProvider<BabyProfile>((ref) async {
  return ref.read(settingsRepositoryProvider).loadBaby();
});
