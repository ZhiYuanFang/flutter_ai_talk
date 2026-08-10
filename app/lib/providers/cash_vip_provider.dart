import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cash_vip_models.dart';
import '../data/cash_vip_repository.dart';
import '../services/vip_payment_service.dart';
import 'authorized_api_client_provider.dart';

final cashVipRepositoryProvider = Provider<CashVipRepository>((ref) {
  return CashVipRepository(ref.watch(authorizedApiClientProvider));
});

final vipPaymentServiceProvider = Provider<VipPaymentService>((ref) {
  return VipPaymentService(ref.watch(cashVipRepositoryProvider));
});

/// VIP 商品（购买页）；失败向上抛给 AsyncValue。
final vipProductProvider = FutureProvider.autoDispose<CashVipProduct>((ref) {
  return ref.watch(cashVipRepositoryProvider).fetchProduct().then((p) {
    if (p == null) {
      throw StateError('VIP 商品为空');
    }
    return p;
  });
});

/// 当前账号 VIP 状态；可 [VipStatusController.refresh]。
final vipStatusProvider =
    AsyncNotifierProvider<VipStatusController, CashVipStatus?>(
  VipStatusController.new,
);

class VipStatusController extends AsyncNotifier<CashVipStatus?> {
  @override
  Future<CashVipStatus?> build() => _load();

  Future<CashVipStatus?> _load() async {
    try {
      return await ref.read(cashVipRepositoryProvider).fetchStatus();
    } catch (_) {
      // 失败不阻塞 CTA：视为未知/非 VIP
      return null;
    }
  }

  /// 支付成功或返回前台后强制刷新。
  Future<CashVipStatus?> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
    return state.valueOrNull;
  }
}
