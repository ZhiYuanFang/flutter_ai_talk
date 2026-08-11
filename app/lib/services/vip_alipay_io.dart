import 'dart:io';

import 'vip_alipay_android.dart' as android_impl;

/// IO 平台入口：仅 Android 调起支付宝；iOS 等走拒绝/否。
Future<Map<dynamic, dynamic>> payWithAlipay(String orderStr) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('仅 Android 使用支付宝');
  }
  return android_impl.payWithAlipay(orderStr);
}

Future<bool> isAlipayInstalled() async {
  if (!Platform.isAndroid) return false;
  return android_impl.isAlipayInstalled();
}
