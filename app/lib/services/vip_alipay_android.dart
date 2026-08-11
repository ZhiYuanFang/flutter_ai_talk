import 'package:tobias/tobias.dart';

import '../api/app_debug_log.dart';

/// Android 专用：经 path 包 `tobias`（仅声明 android 平台）调起支付宝。
Future<Map<dynamic, dynamic>> payWithAlipay(String orderStr) async {
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
  try {
    return await Tobias().isAliPayInstalled;
  } catch (e) {
    AppDebugLog.cashVip('alipay installed check err=$e');
    return false;
  }
}
