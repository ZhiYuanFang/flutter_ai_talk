import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 基础版墙「横向投屏」：关墙后请求预测页弹出同源投屏确认。
final predictionLandscapeCastRequestProvider = NotifierProvider<
    PredictionLandscapeCastRequestNotifier, int?>(
  PredictionLandscapeCastRequestNotifier.new,
);

class PredictionLandscapeCastRequestNotifier extends Notifier<int?> {
  var _seq = 0;

  @override
  int? build() => null;

  /// 发出一次投屏确认请求（单调递增 token）。
  void request() {
    _seq += 1;
    state = _seq;
  }

  /// 预测页已消费后清空，避免重复弹框。
  void clear() {
    state = null;
  }
}

/// 基础版墙「长按语音记录」：关墙后请求「去记录」pill 心跳 3 次（仅吸引注意）。
final predictionGoRecordFabPulseRequestProvider = NotifierProvider<
    PredictionGoRecordFabPulseRequestNotifier, int?>(
  PredictionGoRecordFabPulseRequestNotifier.new,
);

class PredictionGoRecordFabPulseRequestNotifier extends Notifier<int?> {
  var _seq = 0;

  @override
  int? build() => null;

  void request() {
    _seq += 1;
    state = _seq;
  }

  void clear() {
    state = null;
  }
}
