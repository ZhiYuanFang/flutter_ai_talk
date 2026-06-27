import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/env.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';
import 'sign_in_channel_provider.dart';
import 'toast_bus.dart';

/// 带 Bearer 的网关请求；遇 HTTP 401 会静默刷新 token 并重试一次，失败则登出并 Toast。
final authorizedApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppEnv.apiBaseUrl,
    accessTokenProvider: () => ref.read(sessionProvider).accessToken,
    onUnauthorizedRefresh: () => ref.read(sessionProvider).trySilentRefresh(),
    onUnauthorizedFailed: () async {
      final session = ref.read(sessionProvider);
      // 竞态：并发 refresh 赢家可能已写入新 access；瞬时失败也不硬登出。
      if (!session.shouldHardSignOutAfterRefreshFailure) return;

      final wasLoggedIn = session.isLoggedIn;
      await session.signOut();
      await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await ref.read(signInChannelProvider.notifier).clear();
      if (wasLoggedIn) {
        ref.showApiToastError('登录已过期，请重新登录');
      }
    },
  );
});
