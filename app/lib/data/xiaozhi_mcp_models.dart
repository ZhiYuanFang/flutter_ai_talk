// 小智 MCP / 音箱绑定与开通契约模型（gateway camelCase）。

/// 绑定列表项（脱敏；无完整 token）。
class XiaozhiMcpBindingItem {
  const XiaozhiMcpBindingItem({
    required this.id,
    required this.alias,
    required this.tokenMask,
    required this.speakerMac,
    required this.deviceNo,
    required this.status,
    required this.connected,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String alias;
  final String tokenMask;
  final String speakerMac;
  final String deviceNo;
  final int status;
  final bool connected;
  final int createdAt;
  final int updatedAt;

  factory XiaozhiMcpBindingItem.fromJson(Map<String, dynamic> json) {
    return XiaozhiMcpBindingItem(
      id: _asInt(json['id']),
      alias: (json['alias'] ?? '').toString(),
      tokenMask: (json['tokenMask'] ?? '').toString(),
      speakerMac: (json['speakerMac'] ?? '').toString(),
      deviceNo: (json['deviceNo'] ?? '').toString(),
      status: _asInt(json['status']),
      connected: json['connected'] == true,
      createdAt: _asInt(json['createdAt']),
      updatedAt: _asInt(json['updatedAt']),
    );
  }
}

/// 添加成功回执。
class XiaozhiMcpBindingAddResult {
  const XiaozhiMcpBindingAddResult({
    required this.id,
    required this.alias,
    required this.tokenMask,
    required this.speakerMac,
    required this.deviceNo,
  });

  final int id;
  final String alias;
  final String tokenMask;
  final String speakerMac;
  final String deviceNo;

  factory XiaozhiMcpBindingAddResult.fromJson(Map<String, dynamic> json) {
    return XiaozhiMcpBindingAddResult(
      id: _asInt(json['id']),
      alias: (json['alias'] ?? '').toString(),
      tokenMask: (json['tokenMask'] ?? '').toString(),
      speakerMac: (json['speakerMac'] ?? '').toString(),
      deviceNo: (json['deviceNo'] ?? '').toString(),
    );
  }
}

/// 可售永久 SKU。
class XiaozhiMcpProduct {
  const XiaozhiMcpProduct({
    required this.productCode,
    required this.title,
    required this.priceFen,
    required this.originalPriceFen,
    this.appleProductId = '',
    required this.status,
  });

  final String productCode;
  final String title;
  final int priceFen;
  final int originalPriceFen;
  final String appleProductId;
  final int status;

  /// 上架可售。
  bool get isOnSale => status == 1;

  factory XiaozhiMcpProduct.fromJson(Map<String, dynamic> json) {
    return XiaozhiMcpProduct(
      productCode: (json['productCode'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      priceFen: _asInt(json['priceFen']),
      originalPriceFen: _asInt(json['originalPriceFen']),
      appleProductId: (json['appleProductId'] ?? '').toString(),
      status: _asInt(json['status']),
    );
  }
}

/// GET unlock 开通态。
class XiaozhiMcpUnlockView {
  const XiaozhiMcpUnlockView({
    required this.unlocked,
    required this.trialAvailable,
    this.expiresAt = 0,
    this.product,
  });

  final bool unlocked;
  final bool trialAvailable;

  /// unlocked 时：0=永久；>0=试用截止 Unix 秒。
  final int expiresAt;
  final XiaozhiMcpProduct? product;

  /// 可发起添加（已开通或仍可试用）。
  bool get canAdd => unlocked || trialAvailable;

  /// 试用进行中（未永久）。
  bool get isTrialActive => unlocked && expiresAt > 0;

  /// 永久开通。
  bool get isPermanent => unlocked && expiresAt <= 0;

  factory XiaozhiMcpUnlockView.fromJson(Map<String, dynamic> json) {
    XiaozhiMcpProduct? product;
    final raw = json['product'];
    if (raw is Map<String, dynamic>) {
      product = XiaozhiMcpProduct.fromJson(raw);
    } else if (raw is Map) {
      product = XiaozhiMcpProduct.fromJson(Map<String, dynamic>.from(raw));
    }
    return XiaozhiMcpUnlockView(
      unlocked: json['unlocked'] == true,
      trialAvailable: json['trialAvailable'] == true,
      expiresAt: _asInt(json['expiresAt']),
      product: product,
    );
  }
}

/// 运营配置的引导视频项（能力宣传 / 绑定教学）。
class XiaozhiMcpGuideVideoItem {
  const XiaozhiMcpGuideVideoItem({
    required this.slot,
    required this.title,
    required this.videoCdnUrl,
    this.coverCdnUrl = '',
  });

  final String slot;
  final String title;
  final String videoCdnUrl;
  final String coverCdnUrl;

  factory XiaozhiMcpGuideVideoItem.fromJson(Map<String, dynamic> json) {
    return XiaozhiMcpGuideVideoItem(
      slot: (json['slot'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      videoCdnUrl: (json['videoCdnUrl'] ?? '').toString(),
      coverCdnUrl: (json['coverCdnUrl'] ?? '').toString(),
    );
  }
}

/// POST orders 回执（字段对齐功能/VIP 建单）。
class XiaozhiMcpOrder {
  const XiaozhiMcpOrder({
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
  final String appAccountToken;
  final String alipayOrderStr;
  final String payTip;

  factory XiaozhiMcpOrder.fromJson(Map<String, dynamic> json) {
    return XiaozhiMcpOrder(
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

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
