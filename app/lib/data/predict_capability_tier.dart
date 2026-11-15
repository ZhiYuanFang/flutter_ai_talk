import 'feature_unlock_models.dart';

/// 基础版档位本地 logo（墙 hero / 3h 卡左侧；无 catalog featureId）。
const kPredictFreeTierLogoAsset = 'assets/images/pre_basic.png';

/// 基础版能力 demo 种类（映射中档示意控件）。
enum PredictBasicFeatureDemoKind {
  nextEstimate,
  pushRemind,
  homeWidget,
  familyShare,
  landscapeCast,
  voiceBall,
  trendChart,
  xiaozhiSpeaker,
}

/// 基础版墙一条能力（文案 + demo kind）。
class PredictBasicFeatureItem {
  const PredictBasicFeatureItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final PredictBasicFeatureDemoKind kind;
}

/// 基础版 8 条能力（禁算法/亲和等词）。
const kPredictBasicFeatureItems = <PredictBasicFeatureItem>[
  PredictBasicFeatureItem(
    emoji: '⏱️',
    title: '智能估算下次',
    subtitle: '根据喂养频率，帮你预估下一次大概什么时候',
    kind: PredictBasicFeatureDemoKind.nextEstimate,
  ),
  PredictBasicFeatureItem(
    emoji: '🔔',
    title: '智能推送提醒',
    subtitle: '临近预估时刻推送提醒，少盯着手机',
    kind: PredictBasicFeatureDemoKind.pushRemind,
  ),
  PredictBasicFeatureItem(
    emoji: '📱',
    title: '桌面小组件',
    subtitle: '桌面一眼看到接下来的预测',
    kind: PredictBasicFeatureDemoKind.homeWidget,
  ),
  PredictBasicFeatureItem(
    emoji: '👨👩👧👦',
    title: '家庭全员共享',
    subtitle: '同一宝宝，家里人一起看、一起用',
    kind: PredictBasicFeatureDemoKind.familyShare,
  ),
  PredictBasicFeatureItem(
    emoji: '📺',
    title: '横向投屏共享',
    subtitle: '预测页横屏投出来，方便家人一起看',
    kind: PredictBasicFeatureDemoKind.landscapeCast,
  ),
  PredictBasicFeatureItem(
    emoji: '🎙️',
    title: '语音球唤醒对话',
    subtitle: '唤醒后动口完成信息记录与查询，少动手',
    kind: PredictBasicFeatureDemoKind.voiceBall,
  ),
  PredictBasicFeatureItem(
    emoji: '📈',
    title: '多日趋势图',
    subtitle: '多日宝宝信息趋势，变化看得更清楚',
    kind: PredictBasicFeatureDemoKind.trendChart,
  ),
  PredictBasicFeatureItem(
    emoji: '🔊',
    title: '家中音箱 · 免动手',
    subtitle: '连接实体硬件音箱，脱离手机，纯语音记录与查询宝宝日常',
    kind: PredictBasicFeatureDemoKind.xiaozhiSpeaker,
  ),
];

/// Pro 档 description 为空时的短兜底（仍按 MD 渲染）。
const kPredictProTierBodyMarkdownFallback = '更进阶的预测能力，敬请期待。';

/// 预测两档墙 / 3h 标题后缀用的档位。
enum PredictCapabilityTier {
  /// 基础版（客户端标签，无 featureId；展示文案「基础版」）。
  free,

  /// catalog `predict_capability_pro`。
  pro,
}

/// 3h 标题后缀种类（含 syncing 占位）。
enum PredictCapabilityTierLabelKind {
  syncing,
  free,
  pro,
}

/// catalog/Pro eligibility 同步中 → syncing；否则 Pro 优先，否则基础版。
PredictCapabilityTierLabelKind resolvePredictCapabilityTierLabel({
  required bool settleSyncing,
  required FeatureCatalogItem? pro,
}) {
  if (settleSyncing) {
    return PredictCapabilityTierLabelKind.syncing;
  }
  if (isCatalogFeatureTimeValid(pro)) {
    return PredictCapabilityTierLabelKind.pro;
  }
  return PredictCapabilityTierLabelKind.free;
}

/// 后缀展示文案（不含前导「·」）。
String predictCapabilityTierSuffixLabel(PredictCapabilityTierLabelKind kind) {
  switch (kind) {
    case PredictCapabilityTierLabelKind.syncing:
      return '同步中';
    case PredictCapabilityTierLabelKind.free:
      return '基础版';
    case PredictCapabilityTierLabelKind.pro:
      return 'Pro版';
  }
}

/// 墙内 carousel 初始页：仅 ready 档；syncing 不应开墙。
int predictCapabilityTierCarouselIndex(PredictCapabilityTierLabelKind kind) {
  switch (kind) {
    case PredictCapabilityTierLabelKind.syncing:
    case PredictCapabilityTierLabelKind.free:
      return PredictCapabilityTier.free.index;
    case PredictCapabilityTierLabelKind.pro:
      return PredictCapabilityTier.pro.index;
  }
}

/// 墙底栏状态标签（本版无可点开通）。
enum PredictTierFooterKind {
  /// 「正在使用」。
  inUse,

  /// 「敬请期待」（Pro 未开通）。
  comingSoon,
}

/// 按档计算底栏：Free 恒在用；Pro 已开通在用否则敬请期待。
PredictTierFooterKind resolvePredictTierFooter({
  required PredictCapabilityTier tier,
  required FeatureCatalogItem? pro,
}) {
  switch (tier) {
    case PredictCapabilityTier.free:
      return PredictTierFooterKind.inUse;
    case PredictCapabilityTier.pro:
      if (isCatalogFeatureTimeValid(pro)) {
        return PredictTierFooterKind.inUse;
      }
      return PredictTierFooterKind.comingSoon;
  }
}

String predictTierFooterLabel(PredictTierFooterKind kind) {
  switch (kind) {
    case PredictTierFooterKind.inUse:
      return '正在使用';
    case PredictTierFooterKind.comingSoon:
      return '敬请期待';
  }
}

/// Pro「敬请期待」同行月价小字（`¥x/月`）；非 comingSoon / 无价返回空。
///
/// `/月` 写死；金额仅来自 catalog `defaultProduct.priceFen`，不读 `durationDays`、不本地编价。
String predictProComingSoonPriceHint({
  required PredictTierFooterKind footer,
  required FeatureCatalogItem? pro,
}) {
  // 仅未开通敬请期待挂价
  if (footer != PredictTierFooterKind.comingSoon) return '';
  final fen = pro?.defaultProduct?.priceFen ?? 0;
  if (fen <= 0) return '';
  final yuan = fen / 100.0;
  // 整数去小数，否则两位（对齐 payPriceLabel）
  final s = yuan == yuan.roundToDouble()
      ? yuan.toStringAsFixed(0)
      : yuan.toStringAsFixed(2);
  return '¥$s/月';
}
