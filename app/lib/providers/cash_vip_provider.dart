import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cash_vip_models.dart';
import '../data/cash_vip_repository.dart';
import '../services/vip_payment_service.dart';
import 'authorized_api_client_provider.dart';
import 'session_provider.dart';

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

/// 当前账号 VIP 状态；可 [VipStatusController.refresh] / [ensureVipSettled]。
final vipStatusProvider =
    AsyncNotifierProvider<VipStatusController, CashVipStatus?>(
  VipStatusController.new,
);

/// 副作用路径读 `isVip` 前 MUST await（共享 single-flight；失败 fail-closed 为 null）。
Future<CashVipStatus?> ensureVipSettled(
  Ref ref, {
  bool force = false,
}) {
  return ref.read(vipStatusProvider.notifier).ensureSettled(force: force);
}

class VipStatusController extends AsyncNotifier<CashVipStatus?> {
  /// settle 请求合并（含与 build/_load 并发）。
  Future<CashVipStatus?>? _settleInFlight;

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

  /// 确保 VIP 已 settle：未登录秒回；已 AsyncData 非 force 秒回；否则 single-flight 等待/拉取。
  Future<CashVipStatus?> ensureSettled({bool force = false}) {
    // 未登录：不适用 VIP，不打网络。
    if (!ref.read(sessionProvider).isLoggedIn) {
      return Future.value(null);
    }
    // 已有确定结果（含 fail-closed 的 null）且非强制：秒回。
    if (!force) {
      final s = state;
      if (s is AsyncData<CashVipStatus?>) {
        return Future.value(s.value);
      }
    }
    // 合并并发 settle。
    return _settleInFlight ??= _settleImpl(force: force).whenComplete(() {
      _settleInFlight = null;
    });
  }

  Future<CashVipStatus?> _settleImpl({required bool force}) async {
    if (force) {
      return refresh();
    }
    try {
      // 等待 build()/_load 或既有 in-flight；_load 内部已吞错。
      return await future;
    } catch (_) {
      return null;
    }
  }
}
