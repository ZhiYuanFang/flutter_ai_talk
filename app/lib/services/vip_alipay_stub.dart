/// Web / 非 IO：不调起支付宝。
Future<Map<dynamic, dynamic>> payWithAlipay(String orderStr) async {
  throw UnsupportedError('当前平台不支持支付宝');
}

Future<bool> isAlipayInstalled() async => false;
