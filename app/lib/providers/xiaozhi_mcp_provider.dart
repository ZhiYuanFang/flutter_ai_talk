import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/xiaozhi_mcp_binding_repository.dart';
import '../data/xiaozhi_mcp_models.dart';
import '../data/xiaozhi_mcp_unlock_repository.dart';
import '../services/xiaozhi_mcp_payment_service.dart';
import 'authorized_api_client_provider.dart';
import 'cash_vip_provider.dart';
import 'toast_bus.dart';

final xiaozhiMcpBindingRepositoryProvider =
    Provider<XiaozhiMcpBindingRepository>((ref) {
  return XiaozhiMcpBindingRepository(
    ref.watch(authorizedApiClientProvider),
    onToastError: (m) => ref.showApiToastError(m),
  );
});

final xiaozhiMcpUnlockRepositoryProvider =
    Provider<XiaozhiMcpUnlockRepository>((ref) {
  return XiaozhiMcpUnlockRepository(
    ref.watch(authorizedApiClientProvider),
    onToastError: (m) => ref.showApiToastError(m),
  );
});

final xiaozhiMcpPaymentServiceProvider = Provider<XiaozhiMcpPaymentService>((ref) {
  return XiaozhiMcpPaymentService(
    ref.watch(xiaozhiMcpUnlockRepositoryProvider),
    ref.watch(cashVipRepositoryProvider),
  );
});

/// 开通态；写操作后 [invalidate] 刷新。
final xiaozhiMcpUnlockProvider =
    FutureProvider.autoDispose<XiaozhiMcpUnlockView>((ref) {
  return ref.watch(xiaozhiMcpUnlockRepositoryProvider).fetchUnlock();
});

/// 绑定列表；写操作后 [invalidate] 刷新。
final xiaozhiMcpBindingsProvider =
    FutureProvider.autoDispose<List<XiaozhiMcpBindingItem>>((ref) {
  return ref.watch(xiaozhiMcpBindingRepositoryProvider).list();
});

/// 引导视频清单；失败时 repository 已返回 []。
final xiaozhiMcpGuideVideosProvider =
    FutureProvider.autoDispose<List<XiaozhiMcpGuideVideoItem>>((ref) {
  return ref.watch(xiaozhiMcpUnlockRepositoryProvider).listGuideVideos();
});
