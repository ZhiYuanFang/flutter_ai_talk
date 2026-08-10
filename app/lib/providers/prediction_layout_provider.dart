import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/prediction_layout_store.dart';

/// 预测页卡片布局（默认 grid，本地持久化）。
final predictionCardsLayoutProvider = AsyncNotifierProvider<
    PredictionCardsLayoutNotifier, PredictionCardsLayout>(
  PredictionCardsLayoutNotifier.new,
);

class PredictionCardsLayoutNotifier
    extends AsyncNotifier<PredictionCardsLayout> {
  @override
  Future<PredictionCardsLayout> build() => PredictionLayoutStore.load();

  Future<void> setLayout(PredictionCardsLayout layout) async {
    await PredictionLayoutStore.save(layout);
    state = AsyncData(layout);
  }

  Future<void> toggle() async {
    final cur = state.asData?.value ?? PredictionCardsLayout.grid;
    final next = cur == PredictionCardsLayout.grid
        ? PredictionCardsLayout.list
        : PredictionCardsLayout.grid;
    await setLayout(next);
  }
}
