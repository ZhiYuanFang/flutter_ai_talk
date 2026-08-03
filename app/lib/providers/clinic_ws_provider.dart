import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../config/pangbao_ai_consent_store.dart';
import '../voice/clinic_ws_client.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

/// 陪伴页是否曾挂载（懒挂载后为 true；用于允许 Clinic WS 保持连接）。
final companionEverMountedProvider = StateProvider<bool>((ref) => false);

/// 每次进入陪伴页递增，供 KeepAlive 的陪伴页重新执行 tip 注入 /「我来啦」。
final companionEnterSignalProvider = StateProvider<int>((ref) => 0);

/// 壳级 Clinic WS 客户端：仅在 [activateCompanionClinicWs] 后建连；滑离陪伴页不断开。
///
/// 业务说明：provider create 不自动 connect（副作用治理）；由壳在首次进入陪伴时 activate。
final clinicWsClientProvider = Provider<ClinicWsClient>((ref) {
  final client = ClinicWsClient(
    wsUrl: AppEnv.wsClinicUrlEffective,
    ref: ref,
    deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
  );
  ref.onDispose(client.dispose);
  return client;
});

/// 是否具备陪伴 Clinic WS 建连条件：同意 + 登录 + 非空 deviceNo。
bool companionClinicWsEligible(dynamic ref) {
  final loggedIn = ref.read(sessionProvider).isLoggedIn as bool;
  final dn = (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>).asData?.value?.trim();
  return loggedIn && dn != null && dn.isNotEmpty;
}

/// 异步检查同意态后，在陪伴已挂载且具备条件时打开 connectionDesired。
/// [ref] 接受 Riverpod [Ref] 或 [WidgetRef]。
Future<void> activateCompanionClinicWs(dynamic ref) async {
  // 标记曾挂载，后续滑走仍可保持 desired
  ref.read(companionEverMountedProvider.notifier).state = true;
  final consented = await PangbaoAiConsentStore.load();
  if (!consented) return;
  if (!companionClinicWsEligible(ref)) return;
  (ref.read(clinicWsClientProvider) as ClinicWsClient).setConnectionDesired(true);
}

/// 进入陪伴页时确保建连（未 ready 则 setDesired）。
Future<void> ensureCompanionClinicWsConnected(dynamic ref) async {
  final consented = await PangbaoAiConsentStore.load();
  if (!consented) return;
  if (!companionClinicWsEligible(ref)) return;
  ref.read(companionEverMountedProvider.notifier).state = true;
  (ref.read(clinicWsClientProvider) as ClinicWsClient).setConnectionDesired(true);
}

/// 离开 `/home` 壳时断开 Clinic WS（与 UCG/喂养 transport 一并释放）。
/// [ref] 接受 Riverpod [Ref] 或 [WidgetRef]。
void deactivateCompanionClinicWs(dynamic ref) {
  ref.read(companionEverMountedProvider.notifier).state = false;
  // 仅当 provider 已被 watch/read 创建时才操作；用 exists 避免无故创建
  if (ref.exists(clinicWsClientProvider)) {
    ref.read(clinicWsClientProvider).setConnectionDesired(false);
  }
}
