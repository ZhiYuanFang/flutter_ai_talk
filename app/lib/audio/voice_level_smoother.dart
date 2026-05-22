import 'package:flutter/foundation.dart';

/// 攻击快、回落慢的响度平滑，并节流到约 30Hz。
class VoiceLevelSmoother {
  VoiceLevelSmoother(this.notifier);

  final ValueNotifier<double> notifier;

  var _smoothed = 0.0;
  DateTime? _lastEmit;

  static const _attackCoeff = 0.45;
  static const _releaseCoeff = 0.15;
  static const _emitInterval = Duration(milliseconds: 33);

  void pushRaw(double raw) {
    final target = raw.clamp(0.0, 1.0);
    final coeff = target > _smoothed ? _attackCoeff : _releaseCoeff;
    _smoothed += (target - _smoothed) * coeff;

    final now = DateTime.now();
    if (_lastEmit != null && now.difference(_lastEmit!) < _emitInterval) {
      return;
    }
    if ((notifier.value - _smoothed).abs() < 0.015 && target > 0.02) {
      return;
    }
    _lastEmit = now;
    notifier.value = _smoothed;
  }

  void reset() {
    _smoothed = 0;
    _lastEmit = null;
    notifier.value = 0;
  }
}

/// 多柱高度系数（中间柱最高）。
const kHomeVoiceLevelBarWobble = [0.55, 0.85, 1.0, 0.75, 0.6];
