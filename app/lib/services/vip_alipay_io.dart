import 'dart:io';

import 'package:tobias/tobias.dart';

import '../api/app_debug_log.dart';

/// Android 调起支付宝；其它 IO 平台拒绝（iOS 走 Apple IAP）。
Future<Map<dynamic, dynamic>> payWithAlipay(String orderStr) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('仅 Android 使用支付宝');
  }
  final trimmed = orderStr.trim();
  if (trimmed.isEmpty) {
    throw StateError('alipayOrderStr 为空');
  }
  final tobias = Tobias();
  AppDebugLog.cashVip('alipay pay invoke orderStrLen=${trimmed.length}');
  final result = await tobias.pay(trimmed);
  AppDebugLog.cashVip(
    'alipay pay resultStatus=${result['resultStatus']} memo=${result['memo']}',
  );
  return result;
}

Future<bool> isAlipayInstalled() async {
  if (!Platform.isAndroid) return false;
  try {
    return await Tobias().isAliPayInstalled;
  } catch (e) {
    AppDebugLog.cashVip('alipay installed check err=$e');
    return false;
  }
}
