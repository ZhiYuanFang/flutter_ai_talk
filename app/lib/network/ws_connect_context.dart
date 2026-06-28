import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/toast_bus.dart';
import '../session/session_controller.dart';
import '../session/session_device_token_sync.dart';
import 'ws_connection_config.dart';

/// 设备维度鉴权 WS 建连前：刷新 session、对齐 JWT `device_no`。
///
/// 经 [ensureFreshSession] 等待 refresh 单飞；hard sign-out 才可选 toast。
Future<WsConnectContext?> prepareDeviceWsConnectContext(
  Ref ref, {
  required String? deviceNo,
  bool toastOnHardFailure = true,
  bool toastOnDeviceSyncFailure = true,
  bool Function()? shouldToastHardFailure,
}) {
  return _prepareDeviceWsConnectContext(
    readSession: () => ref.read(sessionProvider),
    syncDeviceNo: (dn) => ensureAccessTokenHasDeviceNo(ref, localDeviceNo: dn),
    showError: ref.showApiToastError,
    clearLocalOnHardFailure: () async {
      await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await ref.read(signInChannelProvider.notifier).clear();
    },
    deviceNo: deviceNo,
    toastOnHardFailure: toastOnHardFailure,
    toastOnDeviceSyncFailure: toastOnDeviceSyncFailure,
    shouldToastHardFailure: shouldToastHardFailure,
  );
}

Future<WsConnectContext?> prepareDeviceWsConnectContextFromWidget(
  WidgetRef ref, {
  required String? deviceNo,
  bool toastOnHardFailure = true,
  bool toastOnDeviceSyncFailure = true,
  bool Function()? shouldToastHardFailure,
}) {
  return _prepareDeviceWsConnectContext(
    readSession: () => ref.read(sessionProvider),
    syncDeviceNo: (dn) => ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: dn),
    showError: ref.showApiToastError,
    clearLocalOnHardFailure: () async {
      await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await ref.read(signInChannelProvider.notifier).clear();
    },
    deviceNo: deviceNo,
    toastOnHardFailure: toastOnHardFailure,
    toastOnDeviceSyncFailure: toastOnDeviceSyncFailure,
    shouldToastHardFailure: shouldToastHardFailure,
  );
}

Future<WsConnectContext?> _prepareDeviceWsConnectContext({
  required SessionController Function() readSession,
  required Future<bool> Function(String? deviceNo) syncDeviceNo,
  required void Function(String message) showError,
  required Future<void> Function() clearLocalOnHardFailure,
  required String? deviceNo,
  bool toastOnHardFailure = true,
  bool toastOnDeviceSyncFailure = true,
  bool Function()? shouldToastHardFailure,
}) async {
  final session = readSession();
  if (!session.isLoggedIn) return null;

  final ok = await session.ensureFreshSession();
  if (!ok) {
    if (readSession().shouldHardSignOutAfterRefreshFailure) {
      final shouldToast = toastOnHardFailure &&
          (shouldToastHardFailure?.call() ?? true);
      if (shouldToast) {
        await clearLocalOnHardFailure();
        showError('登录已过期，请重新登录');
      }
    }
    return null;
  }

  final dn = deviceNo?.trim();
  if (dn != null && dn.isNotEmpty) {
    final synced = await syncDeviceNo(dn);
    if (!synced) {
      if (toastOnDeviceSyncFailure) {
        showError('会话刷新失败，请重新登录后再试');
      }
      return null;
    }
  }

  return WsConnectContext(
    accessToken: readSession().accessToken,
    deviceNo: dn,
  );
}

/// 喂养历史：仅在首屏加载完成后才 toast hard sign-out。
bool historyWsShouldToastHardFailure(Ref ref) =>
    ref.read(homeHistoryProvider).initialLoadDone;
