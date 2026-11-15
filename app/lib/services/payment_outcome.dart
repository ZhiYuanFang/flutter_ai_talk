/// 支付结果（供 UI Toast / 导航；功能单与小智共用）。
class VipPaymentOutcome {
  const VipPaymentOutcome({
    required this.success,
    this.message = '',
    this.cancelled = false,
  });

  final bool success;
  final String message;
  final bool cancelled;
}
