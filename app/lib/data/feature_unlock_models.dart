// 商业功能开通：catalog / eligibility / 建单 / 邀请码 / 广告（对齐 Go cash_feature_http）。

import 'package:flutter/material.dart';

import 'event_definition.dart' show tryParseEventColor;

/// 预测开通数量功能 ID（与服务端 FeatureIDPredictionUnlock 一致）。
const kFeatureIdPredictionUnlock = 'prediction_unlock';

/// 值得留意智能提醒功能 ID（与服务端 FeatureIDCareAlertSmartRemind 一致）。
const kFeatureIdCareAlertSmartRemind = 'care_alert_smart_remind';

/// 成长轨迹预测功能 ID（与服务端 FeatureIDGrowthTrajectoryPredict 一致）。
const kFeatureIdGrowthTrajectoryPredict = 'growth_trajectory_predict';

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
    this.defaultCount,
    this.totalActivatableCount,
    this.inviteDurationDays,
    this.adDurationDays,
    this.trialAvailable = false,
    this.inviteAvailable = false,
    this.logo = '',
    this.color = '',
    this.products = const [],
  });

  final String featureId;
  final String title;
  final String description;

  /// 逗号串，如 `payment,invite_code`（广告通道已废弃）。
  final String unlockMethods;
  final bool unlocked;
  final String unlockMethod;
  final int expiresAt;
  final int? allowedCount;

  /// 预测默认免费槽位数（历史字段；槽位能力已删除，勿再作门闸）。
  final int? defaultCount;

  /// 预测可激活天花板（历史字段；槽位能力已删除）。
  final int? totalActivatableCount;

  /// 邀请码授予天数（0=永久）；旧服缺字段为 null，文案须弱化，禁止用付费 SKU 冒充。
  final int? inviteDurationDays;

  /// 广告授予天数（已废弃，解析兼容旧服）。
  final int? adDurationDays;

  /// 该账号对该功能仍有一次免费体验资格（未 claim；已开通时服务端应为 false）。
  final bool trialAvailable;

  /// 该账号仍可用邀请码开通本功能（人×功能未邀成功过）。
  final bool inviteAvailable;

  /// 功能 Logo CDN URL；空则 UI 占位。
  final String logo;

  /// 功能主色 hex（#RGB/#RRGGBB）；空则回退主题 primary。
  final String color;

  /// 预测临时/永久全开哨兵（历史；槽位删除后不再依赖）。
  bool get isPredictionFullAccess => allowedCount != null && allowedCount! < 0;
  final List<FeatureCatalogProduct> products;

  /// 永久已激活条数（历史槽位库存展示）。
  int get permanentActivatedCount {
    final ac = allowedCount;
    if (ac == null || ac < 0) return 0;
    return ac;
  }

  /// 是否已全部永久激活（历史槽位语义；商业门闸勿再用）。
  bool get isPredictionFullyActivated {
    final total = totalActivatableCount ?? 0;
    if (total <= 0) return false;
    return permanentActivatedCount >= total;
  }

  /// 开通中心预测卡右上角文案（历史；过滤槽位卡后不应再展示）。
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

  /// 广告开通已删除；恒 false（兼容旧 catalog 仍带 ad 字段）。
  bool get supportsAd => false;

  /// 须同时具备 invite 通道且服务端仍允许本账号邀请开通。
  bool get supportsInviteCode =>
      unlockMethodSet.contains('invite_code') && inviteAvailable;

  /// 默认选第一项 SKU（与服务端 OrderAsc(product_code) 一致）。
  FeatureCatalogProduct? get defaultProduct =>
      products.isEmpty ? null : products.first;

  /// 支付按钮展示用金额（分→元，保留两位）。
  String get payPriceLabel {
    final fen = defaultProduct?.priceFen ?? 0;
    if (fen <= 0) return '支付开通';
    final yuan = fen / 100.0;
    final s = yuan == yuan.roundToDouble()
        ? yuan.toStringAsFixed(0)
        : yuan.toStringAsFixed(2);
    return '¥$s 支付开通';
  }

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
    final dc = json['defaultCount'];
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
      defaultCount: dc == null ? null : _asInt(dc),
      totalActivatableCount: tac == null ? null : _asInt(tac),
      inviteDurationDays: json.containsKey('inviteDurationDays')
          ? _asInt(json['inviteDurationDays'])
          : null,
      adDurationDays:
          json.containsKey('adDurationDays') ? _asInt(json['adDurationDays']) : null,
      trialAvailable: json['trialAvailable'] == true,
      inviteAvailable: json['inviteAvailable'] == true,
      logo: (json['logo'] ?? '').toString().trim(),
      color: (json['color'] ?? '').toString().trim(),
      products: products,
    );
  }
}

/// 解析功能主色；无效/空则回退 [ColorScheme.primary]。
Color resolveFeatureColor(BuildContext context, FeatureCatalogItem? item) {
  final parsed = tryParseEventColor(item?.color);
  return parsed ?? Theme.of(context).colorScheme.primary;
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
    this.appAccountToken = '',
    this.alipayOrderStr = '',
    this.payTip = '',
  });

  final String orderNo;
  final String productCode;
  final String channel;
  final int amountFen;
  final String appleProductId;
  /// Apple StoreKit appAccountToken（UUID）；购买必带。
  final String appAccountToken;
  final String alipayOrderStr;
  final String payTip;

  factory FeatureOrder.fromJson(Map<String, dynamic> json) {
    return FeatureOrder(
      orderNo: (json['orderNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      channel: (json['channel'] ?? '').toString(),
      amountFen: _asInt(json['amountFen']),
      appleProductId: (json['appleProductId'] ?? '').toString(),
      appAccountToken: (json['appAccountToken'] ?? '').toString(),
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
