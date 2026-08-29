// 商业功能开通：catalog / eligibility / 建单 / 邀请码 / 广告（对齐 Go cash_feature_http）。

/// 预测开通数量功能 ID（与服务端 FeatureIDPredictionUnlock 一致）。
const kFeatureIdPredictionUnlock = 'prediction_unlock';

/// catalog 项内嵌可售 SKU。
class FeatureCatalogProduct {
  const FeatureCatalogProduct({
    required this.productCode,
    required this.priceFen,
    required this.originalPriceFen,
    required this.durationDays,
    required this.grantKind,
    required this.grantQuantity,
    this.appleProductId = '',
  });

  final String productCode;
  final int priceFen;
  final int originalPriceFen;
  final int durationDays;
  final String grantKind;
  final int grantQuantity;
  final String appleProductId;

  bool get showOriginalPrice => originalPriceFen > 0;

  factory FeatureCatalogProduct.fromJson(Map<String, dynamic> json) {
    return FeatureCatalogProduct(
      productCode: (json['productCode'] ?? '').toString(),
      priceFen: _asInt(json['priceFen']),
      originalPriceFen: _asInt(json['originalPriceFen']),
      durationDays: _asInt(json['durationDays']),
      grantKind: (json['grantKind'] ?? '').toString(),
      grantQuantity: _asInt(json['grantQuantity']),
      appleProductId: (json['appleProductId'] ?? '').toString(),
    );
  }
}

/// GET `/cash/app/api/invite/mine`。
class InviteMine {
  const InviteMine({
    required this.code,
    required this.redeemedCount,
  });

  final String code;
  final int redeemedCount;

  factory InviteMine.fromJson(Map<String, dynamic> json) {
    return InviteMine(
      code: (json['code'] ?? '').toString(),
      redeemedCount: _asInt(json['redeemedCount']),
    );
  }
}

/// GET `/cash/app/api/invite/invitees` 单项。
class InviteInvitee {
  const InviteInvitee({
    required this.wxId,
    required this.nickname,
    required this.redeemedAt,
  });

  final int wxId;
  final String nickname;
  final int redeemedAt;

  factory InviteInvitee.fromJson(Map<String, dynamic> json) {
    return InviteInvitee(
      wxId: _asInt(json['wxId']),
      nickname: (json['nickname'] ?? '').toString(),
      redeemedAt: _asInt(json['redeemedAt']),
    );
  }
}

/// GET `/cash/app/api/feature/catalog` 整包（含页级群二维码）。
class FeatureCatalogPayload {
  const FeatureCatalogPayload({
    this.items = const [],
    this.inviteGroupQrUrl = '',
  });

  final List<FeatureCatalogItem> items;
  final String inviteGroupQrUrl;

  factory FeatureCatalogPayload.fromJson(Map<String, dynamic> json) {
    final raw = json['list'];
    final out = <FeatureCatalogItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          out.add(FeatureCatalogItem.fromJson(e));
        } else if (e is Map) {
          out.add(FeatureCatalogItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return FeatureCatalogPayload(
      items: out,
      inviteGroupQrUrl: (json['inviteGroupQrUrl'] ?? '').toString().trim(),
    );
  }
}

/// GET `/cash/app/api/feature/catalog` 单项。
class FeatureCatalogItem {
  const FeatureCatalogItem({
    required this.featureId,
    required this.title,
    required this.description,
    required this.unlockMethods,
    required this.unlocked,
    this.unlockMethod = '',
    this.expiresAt = 0,
    this.allowedCount,
    this.totalActivatableCount,
    this.products = const [],
  });

  final String featureId;
  final String title;
  final String description;

  /// 逗号串，如 `payment,invite_code,ad`。
  final String unlockMethods;
  final bool unlocked;
  final String unlockMethod;
  final int expiresAt;
  final int? allowedCount;

  /// 预测可激活天花板：Go catalog 聚合的字典**非叶子**总数（仅 prediction_unlock）。
  /// 「已全部激活」只认本字段；不得用客户端可见预测行数重算。
  final int? totalActivatableCount;

  /// 预测临时/永久全开哨兵（与服务端 AllowedCountFullAccessSentinel 一致）。
  bool get isPredictionFullAccess => allowedCount != null && allowedCount! < 0;
  final List<FeatureCatalogProduct> products;

  /// 永久已激活条数（≥0；哨兵 -1 不计入库存展示）= 解锁槽位数 N。
  int get permanentActivatedCount {
    final ac = allowedCount;
    if (ac == null || ac < 0) return 0;
    return ac;
  }

  /// 是否已全部永久激活：仅对照服务端非叶子 total（须 total>0 且 activated≥total）。
  bool get isPredictionFullyActivated {
    final total = totalActivatableCount ?? 0;
    if (total <= 0) return false;
    return permanentActivatedCount >= total;
  }

  /// 开通中心预测卡右上角文案（库存态；与列表可见行数解耦）。
  String get predictionActivationBadgeCopy {
    if (isPredictionFullyActivated) return '已全部激活';
    return '已激活 $permanentActivatedCount 个';
  }

  /// 解析后的开通方式集合。
  Set<String> get unlockMethodSet {
    return unlockMethods
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  bool get supportsPayment =>
      unlockMethodSet.contains('payment') && products.isNotEmpty;

  bool get supportsAd => unlockMethodSet.contains('ad');

  bool get supportsInviteCode => unlockMethodSet.contains('invite_code');

  /// 默认选第一项 SKU（与服务端 OrderAsc(product_code) 一致）。
  FeatureCatalogProduct? get defaultProduct =>
      products.isEmpty ? null : products.first;

  factory FeatureCatalogItem.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = <FeatureCatalogProduct>[];
    if (rawProducts is List) {
      for (final e in rawProducts) {
        if (e is Map<String, dynamic>) {
          products.add(FeatureCatalogProduct.fromJson(e));
        } else if (e is Map) {
          products.add(
            FeatureCatalogProduct.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final ac = json['allowedCount'];
    final tac = json['totalActivatableCount'];
    return FeatureCatalogItem(
      featureId: (json['featureId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      unlockMethods: (json['unlockMethods'] ?? '').toString(),
      unlocked: json['unlocked'] == true,
      unlockMethod: (json['unlockMethod'] ?? '').toString(),
      expiresAt: _asInt(json['expiresAt']),
      allowedCount: ac == null ? null : _asInt(ac),
      totalActivatableCount: tac == null ? null : _asInt(tac),
      products: products,
    );
  }
}

/// GET `/cash/app/api/ucg/eligibility`。
class UcgEligibility {
  const UcgEligibility({
    required this.qualified,
    required this.requiredDays,
    required this.effectiveDays,
    required this.remainingDays,
    this.message = '',
  });

  final bool qualified;
  final int requiredDays;
  final int effectiveDays;
  final int remainingDays;
  final String message;

  factory UcgEligibility.fromJson(Map<String, dynamic> json) {
    return UcgEligibility(
      qualified: json['qualified'] == true,
      requiredDays: _asInt(json['requiredDays']),
      effectiveDays: _asInt(json['effectiveDays']),
      remainingDays: _asInt(json['remainingDays']),
      message: (json['message'] ?? '').toString(),
    );
  }
}

/// POST feature/orders 回执（字段对齐 VIP 建单）。
class FeatureOrder {
  const FeatureOrder({
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

  factory FeatureOrder.fromJson(Map<String, dynamic> json) {
    return FeatureOrder(
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

/// 开通方式展示文案。
String featureUnlockMethodLabel(String method) {
  switch (method.trim()) {
    case 'payment':
      return '支付开通';
    case 'ad':
      return '看广告';
    case 'invite_code':
      return '邀请码';
    case 'vip':
      return '月卡';
    default:
      return method.trim().isEmpty ? '已开通' : method.trim();
  }
}

/// 时长文案：0/缺失 → 永久。
String featureDurationCopy(int durationDays) {
  if (durationDays <= 0) return '永久';
  return '$durationDays 天';
}

/// 剩余天数（expiresAt unix 秒；0 → 永久）。
String featureRemainingDaysCopy(int expiresAt, {DateTime? now}) {
  if (expiresAt <= 0) return '永久';
  final n = now ?? DateTime.now();
  final end = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
  final days = end.difference(n).inDays;
  if (days < 0) return '已过期';
  if (days == 0) return '不足 1 天';
  return '剩余 $days 天';
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
