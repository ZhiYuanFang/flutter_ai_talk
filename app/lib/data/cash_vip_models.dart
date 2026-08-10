// Cash VIP 网关契约模型（对齐 go_ai_talk `api/v1/cash_vip_http.go`）。

/// 一期默认商品码（与后端 seed / 建单默认一致）。
const kCashVipDefaultProductCode = 'vip_monthly_19';

/// GET `/cash/app/api/vip/product` 的 data。
class CashVipProduct {
  const CashVipProduct({
    required this.productCode,
    required this.title,
    required this.priceFen,
    required this.originalPriceFen,
    required this.durationDays,
    required this.appleProductId,
  });

  final String productCode;
  final String title;
  final int priceFen;
  final int originalPriceFen;
  final int durationDays;
  final String appleProductId;

  /// 是否展示划线原价（原价 > 0）。
  bool get showOriginalPrice => originalPriceFen > 0;

  factory CashVipProduct.fromJson(Map<String, dynamic> json) {
    return CashVipProduct(
      productCode: (json['productCode'] ?? kCashVipDefaultProductCode).toString(),
      title: (json['title'] ?? 'VIP').toString(),
      priceFen: _asInt(json['priceFen']),
      originalPriceFen: _asInt(json['originalPriceFen']),
      durationDays: _asInt(json['durationDays']),
      appleProductId: (json['appleProductId'] ?? '').toString(),
    );
  }
}

/// GET `/cash/app/api/vip/status` 的 data。
class CashVipStatus {
  const CashVipStatus({
    required this.wxId,
    required this.isVip,
    required this.expireAt,
  });

  final int wxId;
  final bool isVip;
  final int expireAt;

  factory CashVipStatus.fromJson(Map<String, dynamic> json) {
    return CashVipStatus(
      wxId: _asInt(json['wxId']),
      isVip: json['isVip'] == true,
      expireAt: _asInt(json['expireAt']),
    );
  }
}

/// POST `/cash/app/api/vip/orders` 的 data。
class CashVipOrder {
  const CashVipOrder({
    required this.orderNo,
    required this.productCode,
    required this.channel,
    required this.amountFen,
    this.appleProductId = '',
    this.alipayOrderStr = '',
    this.payTip = '',
  });

  final String orderNo;
  final String productCode;
  final String channel;
  final int amountFen;
  final String appleProductId;
  final String alipayOrderStr;
  final String payTip;

  factory CashVipOrder.fromJson(Map<String, dynamic> json) {
    return CashVipOrder(
      orderNo: (json['orderNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      channel: (json['channel'] ?? '').toString(),
      amountFen: _asInt(json['amountFen']),
      appleProductId: (json['appleProductId'] ?? '').toString(),
      alipayOrderStr: (json['alipayOrderStr'] ?? '').toString(),
      payTip: (json['payTip'] ?? '').toString(),
    );
  }
}

/// 分 → 展示用元字符串（两位小数）。
String formatVipFenYuan(int fen) {
  final yuan = fen / 100.0;
  return yuan.toStringAsFixed(2);
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
