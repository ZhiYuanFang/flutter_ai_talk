import 'package:flutter/services.dart';

const _channel = MethodChannel('com.pangbao.pangbao_app/native_splash');

Future<void> hideNativeSplash() async {
  try {
    await _channel.invokeMethod<void>('hide');
  } catch (_) {
    // 非 Android 或未注册 channel 时忽略。
  }
}
