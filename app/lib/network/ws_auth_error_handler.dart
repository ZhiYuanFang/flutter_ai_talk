import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ai_quota_codes.dart';
import '../providers/ai_quota_dialog_bus.dart';
import '../providers/session_provider.dart';

/// WS auth/quota error 帧处理结果。
class WsAuthQuotaHandleResult {
  const WsAuthQuotaHandleResult({
    this.scheduleReconnect = false,
    this.forwardToUi = true,
    this.requestLoginDialog = false,
  });

  /// 是否 schedule reconnect（silent refresh 成功时为 true）。
  final bool scheduleReconnect;

  /// 是否将 error 帧转发给业务 UI（silent refresh 成功时为 false）。
  final bool forwardToUi;

  /// hard refresh 失效时是否应弹登录引导（由调用方经 [Ref.requestAiQuotaDialog] 等展示）。
  final bool requestLoginDialog;
}

/// 统一 WS 鉴权/额度 error 策略：refresh in-flight 不打扰 → silent refresh → 最后才登录 UX。
Future<WsAuthQuotaHandleResult> handleWsAuthOrQuotaError(
  Ref ref,
  Map<String, dynamic> frame, {
  void Function(int code)? onQuotaDialog,
  void Function(String message)? onGenericError,
  bool genericErrorSchedulesReconnect = false,
}) {
  return _handleWsAuthOrQuotaError(
    isRefreshInFlight: () => ref.read(sessionProvider).isRefreshInFlight,
    trySilentRefresh: () => ref.read(sessionProvider).trySilentRefresh(),
    shouldHardSignOut: () => ref.read(sessionProvider).shouldHardSignOutAfterRefreshFailure,
    requestQuotaDialog: (code) {
      if (onQuotaDialog != null) {
        onQuotaDialog(code);
      } else {
        ref.requestAiQuotaDialog(code);
      }
    },
    frame: frame,
    onGenericError: onGenericError,
    genericErrorSchedulesReconnect: genericErrorSchedulesReconnect,
  );
}

Future<WsAuthQuotaHandleResult> handleWsAuthOrQuotaErrorFromWidget(
  WidgetRef ref,
  Map<String, dynamic> frame, {
  void Function(int code)? onQuotaDialog,
  void Function(String message)? onGenericError,
  bool genericErrorSchedulesReconnect = false,
}) {
  return _handleWsAuthOrQuotaError(
    isRefreshInFlight: () => ref.read(sessionProvider).isRefreshInFlight,
    trySilentRefresh: () => ref.read(sessionProvider).trySilentRefresh(),
    shouldHardSignOut: () => ref.read(sessionProvider).shouldHardSignOutAfterRefreshFailure,
    requestQuotaDialog: (code) {
      if (onQuotaDialog != null) {
        onQuotaDialog(code);
      } else {
        ref.requestAiQuotaDialog(code);
      }
    },
    frame: frame,
    onGenericError: onGenericError,
    genericErrorSchedulesReconnect: genericErrorSchedulesReconnect,
  );
}

Future<WsAuthQuotaHandleResult> _handleWsAuthOrQuotaError({
  required bool Function() isRefreshInFlight,
  required Future<bool> Function() trySilentRefresh,
  required bool Function() shouldHardSignOut,
  required void Function(int code) requestQuotaDialog,
  required Map<String, dynamic> frame,
  void Function(String message)? onGenericError,
  bool genericErrorSchedulesReconnect = false,
}) async {
  if (isRefreshInFlight()) {
    return const WsAuthQuotaHandleResult(forwardToUi: false);
  }

  final code = parseWsErrorBusinessCode(frame);
  if (code == kAiCodeQuotaExhausted) {
    requestQuotaDialog(kAiCodeQuotaExhausted);
    return const WsAuthQuotaHandleResult(forwardToUi: true);
  }

  if (code == kAiCodeNotLoggedIn) {
    final ok = await trySilentRefresh();
    if (ok) {
      return const WsAuthQuotaHandleResult(
        scheduleReconnect: true,
        forwardToUi: false,
      );
    }
    if (shouldHardSignOut()) {
      return const WsAuthQuotaHandleResult(
        forwardToUi: true,
        requestLoginDialog: true,
      );
    }
    return const WsAuthQuotaHandleResult(forwardToUi: true);
  }

  if (onGenericError != null) {
    final msg = frame['message'] as String? ?? '连接异常';
    onGenericError(msg);
  }
  return WsAuthQuotaHandleResult(
    scheduleReconnect: genericErrorSchedulesReconnect,
    forwardToUi: code == null,
  );
}
