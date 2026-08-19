import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/prediction_landscape_column_store.dart';

final predictionLandscapeColumnProvider =
    AsyncNotifierProvider<PredictionLandscapeColumnNotifier, int?>(
  PredictionLandscapeColumnNotifier.new,
);

class PredictionLandscapeColumnNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() => PredictionLandscapeColumnStore.loadRaw();

  Future<void> setCount(int count) async {
    final v = count.clamp(kLandscapeColumnCountMin, kLandscapeColumnCountMax);
    state = AsyncData(v);
    await PredictionLandscapeColumnStore.save(v);
  }

  Future<void> increment(int current) async {
    if (current >= kLandscapeColumnCountMax) return;
    await setCount(current + 1);
  }

  Future<void> decrement(int current) async {
    if (current <= kLandscapeColumnCountMin) return;
    await setCount(current - 1);
  }
}
