import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 预测页屏幕常亮：沉浸投屏与语音思考各占一个原因，任一仍需要则保持点亮。
class PredictionWakeLock {
  PredictionWakeLock._();

  static var _immersive = false;
  static var _thinking = false;

  /// 横屏沉浸投屏是否要求常亮。
  static Future<void> setImmersive(bool hold) => _set(immersive: hold);

  /// 语音思考窗是否要求常亮。
  static Future<void> setThinking(bool hold) => _set(thinking: hold);

  static Future<void> _set({bool? immersive, bool? thinking}) async {
    if (immersive != null) _immersive = immersive;
    if (thinking != null) _thinking = thinking;
    if (kIsWeb) return;
    try {
      if (_immersive || _thinking) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // 平台失败不阻断会话；下次原因变化再试。
    }
  }
}
