import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/app_debug_log.dart';
import '../config/app_notification_preference_store.dart';
import '../ucg/push/ucg_push_native.dart';
import 'app_push_registration_provider.dart';
import 'session_provider.dart';

/// 应用层消息通知偏好（默认 true）。
final appNotificationPreferenceProvider =
    AsyncNotifierProvider<AppNotificationPreferenceNotifier, bool>(
  AppNotificationPreferenceNotifier.new,
);

class AppNotificationPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => AppNotificationPreferenceStore.load();

  /// 写入偏好；Off → unregister；On → 尝试 register。
  Future<void> setEnabled(bool enabled) async {
    await AppNotificationPreferenceStore.save(enabled);
    state = AsyncData(enabled);
    AppDebugLog.ucgPush('notification preference enabled=$enabled');
    if (!enabled) {
      // 关闭：注销 token，阻止后续自动注册。
      await ref.read(appPushRegistrationServiceProvider).unregister();
      return;
    }
    // 开启：刷新系统授权后再同步注册。
    await ref.read(osNotificationAuthProvider.notifier).refresh();
    if (ref.read(sessionProvider).isLoggedIn) {
      await syncAppPushRegistration(ref);
    }
  }
}

/// 系统通知授权态（只读探测）。
final osNotificationAuthProvider =
    AsyncNotifierProvider<OsNotificationAuthNotifier, OsNotificationAuth>(
  OsNotificationAuthNotifier.new,
);

class OsNotificationAuthNotifier extends AsyncNotifier<OsNotificationAuth> {
  @override
  Future<OsNotificationAuth> build() => UcgPushNative.notificationAuthStatus();

  /// 重新探测（resume / 授权后调用）。
  Future<OsNotificationAuth> refresh() async {
    final next = await UcgPushNative.notificationAuthStatus();
    state = AsyncData(next);
    AppDebugLog.ucgPush('notification auth status=$next');
    return next;
  }

  /// 引导开启：先 request；无框或仍未授权则打开系统设置。
  Future<bool> requestOrOpenSettings() async {
    final cur = state.value ?? await refresh();
    if (cur == OsNotificationAuth.unsupported) return false;
    // 已拒绝到系统层：直接去设置。
    if (cur == OsNotificationAuth.permanentlyDenied) {
      AppDebugLog.ucgPush('notification open settings permanentlyDenied');
      await openAppSettings();
      return false;
    }
    final ok = await UcgPushNative.requestNotificationPermission();
    final next = await refresh();
    if (ok || next == OsNotificationAuth.granted) return true;
    // 国产机/设置里关通知时 request 常静默失败，须跳转系统设置。
    AppDebugLog.ucgPush('notification request no-op status=$next open settings');
    await openAppSettings();
    return false;
  }
}

/// 预测页通知横条：本会话已关闭（内存，杀进程重置）。
final notificationOptInBannerDismissedProvider =
    StateProvider<bool>((ref) => false);

/// 是否应在竖屏预测页展示通知引导横条（不含横屏判断，由 UI 再滤）。
bool shouldShowNotificationOptInBanner({
  required bool loggedIn,
  required bool preferenceEnabled,
  required OsNotificationAuth? osAuth,
  required bool sessionDismissed,
}) {
  if (kIsWeb) return false;
  if (!loggedIn) return false;
  if (!preferenceEnabled) return false;
  if (sessionDismissed) return false;
  if (osAuth == null) return false;
  if (osAuth == OsNotificationAuth.granted) return false;
  if (osAuth == OsNotificationAuth.unsupported) return false;
  return true;
}

/// App resume：刷新系统通知授权态；已登录则 sync（偏好 Off / 未授权时仍拉起 LA，设备 push 在 sync 内按偏好跳过）。
Future<void> onAppResumeNotificationSync(dynamic ref) async {
  if (kIsWeb) return;
  await ref.read(osNotificationAuthProvider.notifier).refresh();
  if (!ref.read(sessionProvider).isLoggedIn) return;
  await syncAppPushRegistration(ref);
}
