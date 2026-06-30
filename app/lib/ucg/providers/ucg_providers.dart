import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/app_debug_log.dart';
import '../../bootstrap/pangbao_transport_release.dart';
import '../../providers/authorized_api_client_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_baby.dart';
import '../../providers/toast_bus.dart';
import '../../session/session_controller.dart';
import '../../session/token_expiry.dart';
import '../../network/ws_session_binding.dart';
import '../data/ucg_api_client.dart';
import '../data/ucg_compose_draft_store.dart';
import '../data/ucg_models.dart';
import '../data/ucg_location.dart';
import '../data/ucg_repository.dart';
import '../push/ucg_push_registration_service.dart';

final ucgPushRegistrationServiceProvider = Provider<UcgPushRegistrationService>((ref) {
  final service = UcgPushRegistrationService(api: ref.watch(ucgApiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

Future<void>? _syncUcgUnreadInFlight;

/// UCG Home 会话是否已激活（WS + unread + push）；provider 创建时不自动激活。
var _ucgHomeSessionActive = false;

/// 本会话 UCG WS 首次 ready 后 baseline HTTP 是否已触发。
var _ucgUnreadBaselineSynced = false;

bool get ucgHomeSessionActive => _ucgHomeSessionActive;

void resetUcgHomeSessionState() {
  _ucgHomeSessionActive = false;
  _ucgUnreadBaselineSynced = false;
}

/// gate 后串行激活 UCG：unread HTTP → chat WS → push register（避免 iOS 同 host burst）。
Future<void> activateUcgHomeSession(
  Ref ref, {
  bool requireHomeMounted = true,
}) async {
  if (requireHomeMounted && !PangbaoHomeTransportGate.isHomeMounted) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;

  final repo = ref.read(ucgRepositoryProvider);
  if (_ucgHomeSessionActive) {
    _syncUcgWsDesired(ref, repo);
    return;
  }
  _ucgHomeSessionActive = true;

  await syncUcgUnreadFromServer(ref);
  await syncUcgLauncherBadgeFromUnread(ref);
  _ucgUnreadBaselineSynced = true;
  repo.setWsConnectionDesired(true);
  await _syncUcgPushRegistration(ref);
}

/// 离开 Home / release：关闭 chat WS，重置会话标记（不 dispose provider）。
Future<void> deactivateUcgHomeSession(Ref ref) async {
  resetUcgHomeSessionState();
  if (ref.exists(ucgRepositoryProvider)) {
    ref.read(ucgRepositoryProvider).setWsConnectionDesired(false);
  }
}

void _syncUcgWsDesired(Ref ref, UcgRepository repo) {
  if (!_ucgHomeSessionActive || !PangbaoHomeTransportGate.isHomeMounted) {
    repo.setWsConnectionDesired(false);
    return;
  }
  final loggedIn = ref.read(sessionProvider).isLoggedIn;
  final wxId = ref.read(ucgCurrentUserIdProvider);
  if (loggedIn && isUcgWxAccountBound(wxId)) {
    repo.setWsConnectionDesired(true);
  } else {
    repo.setWsConnectionDesired(false);
  }
}

Future<void> syncUcgUnreadAndBadge(Ref ref) async {
  await syncUcgUnreadFromServer(ref);
  await syncUcgLauncherBadgeFromUnread(ref);
}

/// HTTP 校准未读（会话 + 互动 OR）；WS ready baseline / resume / 登录 / 已读 reconcile 使用。
Future<void> syncUcgUnreadFromServer(Ref ref) async {
  if (_syncUcgUnreadInFlight != null) {
    await _syncUcgUnreadInFlight;
    return;
  }
  final run = _syncUcgUnreadFromServerOnce(ref);
  _syncUcgUnreadInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_syncUcgUnreadInFlight, run)) {
      _syncUcgUnreadInFlight = null;
    }
  }
}

Future<void> _syncUcgUnreadFromServerOnce(Ref ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
  try {
    final ok = await ref.read(sessionProvider).ensureFreshSession();
    if (!ok) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
    final repo = ref.read(ucgRepositoryProvider);
    final notifPage = await repo.fetchCommentNotifications(page: 1);
    final convPage = await repo.fetchConversations(page: 1);
    final chatUnread = convPage.items.fold<int>(0, (s, c) => s + c.unreadCount);
    ref.read(ucgUnreadCountProvider.notifier).state = chatUnread + notifPage.unreadCount;
  } catch (e) {
    AppDebugLog.ucgUnread('sync err=$e');
  }
}

/// WS 他人私信到达：本地未读 +1，不发起 HTTP（方案 A）。
void bumpUcgUnreadOptimisticChat(Ref ref, UcgChatMessage msg) {
  if (msg.isMine) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
  final next = ref.read(ucgUnreadCountProvider) + 1;
  ref.read(ucgUnreadCountProvider.notifier).state = next;
  AppDebugLog.ucgUnread(
    'optimistic +1 chat conv=${msg.conversationId} isMine=false count=$next',
  );
}

/// WS 互动通知到达：本地未读 +1。
void bumpUcgUnreadOptimisticNotification(Ref ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
  final next = ref.read(ucgUnreadCountProvider) + 1;
  ref.read(ucgUnreadCountProvider.notifier).state = next;
  AppDebugLog.ucgUnread('optimistic +1 notification count=$next');
}

/// UCG WS 本会话首次 ready：HTTP baseline 一次（不重试 reconnect）。
void maybeSyncUcgUnreadBaselineOnWsReady(Ref ref) {
  if (!_ucgHomeSessionActive) return;
  if (_ucgUnreadBaselineSynced) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
  _ucgUnreadBaselineSynced = true;
  unawaited(() async {
    await syncUcgUnreadFromServer(ref);
    AppDebugLog.ucgUnread(
      'baseline ws ready count=${ref.read(ucgUnreadCountProvider)}',
    );
  }());
}

Future<void> syncUcgLauncherBadgeFromUnread(Ref ref) async {
  if (kIsWeb) return;
  final count = ref.read(ucgUnreadCountProvider);
  try {
    if (count <= 0) {
      await FlutterAppBadger.removeBadge();
    } else {
      await FlutterAppBadger.updateBadgeCount(count);
    }
  } catch (_) {}
}

Future<void> _syncUcgPushRegistration(Ref ref) async {
  if (kIsWeb) return;
  final session = ref.read(sessionProvider);
  final wxId = ref.read(ucgCurrentUserIdProvider);
  final push = ref.read(ucgPushRegistrationServiceProvider);
  if (!session.isLoggedIn || !isUcgWxAccountBound(wxId)) {
    await push.unregister();
    return;
  }
  await push.registerIfEligible(isLoggedIn: true, wxBound: true);
}

/// Resume / 前台恢复时 HTTP 校准未读并同步启动器角标。
final ucgUnreadSyncProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (!_ucgHomeSessionActive) return;
    await syncUcgUnreadFromServer(ref);
    await syncUcgLauncherBadgeFromUnread(ref);
  };
});

final ucgApiClientProvider = Provider<UcgApiClient>((ref) {
  return UcgApiClient(ref.watch(authorizedApiClientProvider));
});

final ucgComposeDraftStoreProvider = Provider<UcgComposeDraftStore>((ref) {
  return UcgComposeDraftStore();
});

/// 从 JWT `sub` 派生 UCG wxId；登出或未登录时为 null。
final ucgCurrentUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return null;
  return readJwtWxId(session.accessToken);
});

final ucgRepositoryProvider = Provider<UcgRepository>((ref) {
  final repo = UcgRepository(
    api: ref.watch(ucgApiClientProvider),
    ref: ref,
    userIdGetter: () => ref.read(ucgCurrentUserIdProvider),
    accessTokenGetter: () => ref.read(sessionProvider).accessToken,
    isLoggedInGetter: () => ref.read(sessionProvider).isLoggedIn,
    prepareAccessToken: () async {
      final session = ref.read(sessionProvider);
      if (!session.isLoggedIn) return null;
      final ok = await session.ensureFreshSession();
      if (!ok) return null;
      return ref.read(sessionProvider).accessToken;
    },
    onWsErrorToast: (message) => ref.showApiToastError(message),
  );
  ref.onDispose(repo.dispose);

  ref.listen<int>(ucgUnreadCountProvider, (_, __) {
    unawaited(syncUcgLauncherBadgeFromUnread(ref));
  });

  final push = ref.read(ucgPushRegistrationServiceProvider);
  unawaited(push.bindTokenRefreshListener(() async {
    if (!_ucgHomeSessionActive) return;
    await _syncUcgPushRegistration(ref);
  }));

  ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
    if (!loggedIn) {
      resetUcgHomeSessionState();
      _syncUcgWsDesired(ref, repo);
      ref.read(ucgUnreadCountProvider.notifier).state = 0;
      unawaited(push.unregister());
      return;
    }
    _syncUcgWsDesired(ref, repo);
    if (_ucgHomeSessionActive) {
      unawaited(syncUcgUnreadAndBadge(ref));
      unawaited(_syncUcgPushRegistration(ref));
    }
  });
  ref.listen<String?>(ucgCurrentUserIdProvider, (_, __) {
    _syncUcgWsDesired(ref, repo);
    if (_ucgHomeSessionActive) {
      unawaited(_syncUcgPushRegistration(ref));
    }
  });
  ref.listen<String?>(sessionProvider.select((s) => s.accessToken), (prev, next) {
    if (next == null || next.isEmpty) return;
    if (!_ucgHomeSessionActive || !PangbaoHomeTransportGate.isHomeMounted) return;
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (SessionController.isAccessTokenRotation(prev, next) &&
        loggedIn &&
        isUcgWxAccountBound(wxId)) {
      unawaited(repo.reconnectChatWebSocket(resetStrike: false));
    }
  });
  bindAuthenticatedWsSession(
    ref,
    reconnect: ({bool resetStrike = false}) => repo.reconnectChatWebSocket(resetStrike: resetStrike),
    shouldReconnect: () {
      if (!_ucgHomeSessionActive) return false;
      if (!PangbaoHomeTransportGate.isHomeMounted) return false;
      if (!ref.read(sessionProvider).isLoggedIn) return false;
      return isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider));
    },
  );

  final notifSub = repo.notificationEvents.listen((_) {
    ref.read(ucgNotificationsChangedProvider.notifier).state++;
    bumpUcgUnreadOptimisticNotification(ref);
  });
  final msgSub = repo.incomingMessages.listen((msg) {
    bumpUcgUnreadOptimisticChat(ref, msg);
  });
  var wsWasReady = repo.isWsConnected;
  if (wsWasReady) {
    maybeSyncUcgUnreadBaselineOnWsReady(ref);
  }
  final wsReadySub = repo.wsReadyStream.listen((ready) {
    if (ready && !wsWasReady) {
      maybeSyncUcgUnreadBaselineOnWsReady(ref);
    }
    wsWasReady = ready;
  });
  ref.onDispose(() {
    notifSub.cancel();
    msgSub.cancel();
    wsReadySub.cancel();
  });

  return repo;
});

final ucgUnreadCountProvider = StateProvider<int>((ref) => 0);

/// Bumped when WS `comment_notification` arrives or notifications marked read.
final ucgNotificationsChangedProvider = StateProvider<int>((ref) => 0);

void bumpUcgNotificationsRefresh(WidgetRef ref) {
  ref.read(ucgNotificationsChangedProvider.notifier).state++;
}

/// 单帖详情（进入详情页 refresh）。
final ucgPostDetailProvider = FutureProvider.autoDispose.family<UcgPost, String>((ref, postId) async {
  ref.watch(ucgPostsChangedProvider);
  final coords = await readCurrentCoordsIfGranted(ref);
  return ref.read(ucgRepositoryProvider).fetchPost(
        postId,
        lat: coords?.lat,
        lng: coords?.lng,
      );
});

/// 互动消息分页（首屏）。
final ucgCommentNotificationsProvider =
    FutureProvider.autoDispose<UcgPagedCommentNotifications>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) {
    return const UcgPagedCommentNotifications(
      items: [],
      page: 1,
      pageSize: kUcgPageSize,
      total: 0,
      unreadCount: 0,
    );
  }
  ref.watch(ucgNotificationsChangedProvider);
  return ref.read(ucgRepositoryProvider).fetchCommentNotifications(page: 1);
});

/// Incremented after a post is created so square / 我的动态 feeds refresh.
final ucgPostsChangedProvider = StateProvider<int>((ref) => 0);

/// Bumped when leaving chat or focusing消息 Tab so会话列表重新拉取。
final ucgConversationsChangedProvider = StateProvider<int>((ref) => 0);

void bumpUcgConversationsRefresh(WidgetRef ref) {
  ref.read(ucgConversationsChangedProvider.notifier).state++;
}

/// 消息会话列表（首屏）；进入消息 Tab 或离开聊天页时随 [ucgConversationsChangedProvider] 刷新。
final ucgConversationsProvider = FutureProvider.autoDispose<UcgPagedConversations>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) {
    return const UcgPagedConversations(items: [], page: 1, pageSize: kUcgPageSize, total: 0);
  }
  final wxId = ref.watch(ucgCurrentUserIdProvider);
  if (!isUcgWxAccountBound(wxId)) {
    return const UcgPagedConversations(items: [], page: 1, pageSize: kUcgPageSize, total: 0);
  }
  ref.watch(ucgConversationsChangedProvider);
  final repo = ref.read(ucgRepositoryProvider);
  final page = await repo.fetchConversations(page: 1);
  final enriched = await repo.enrichConversationsWithPeerProfiles(page.items);
  return UcgPagedConversations(
    items: enriched,
    page: page.page,
    pageSize: page.pageSize,
    total: page.total,
  );
});

/// 我的动态列表；发帖/删除后随 [ucgPostsChangedProvider] 刷新。
final ucgMyPostsProvider = FutureProvider.autoDispose<List<UcgPost>>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) return [];
  final wxId = ref.watch(ucgCurrentUserIdProvider);
  if (!isUcgWxAccountBound(wxId)) return [];
  ref.watch(ucgPostsChangedProvider);
  final page = await ref.read(ucgRepositoryProvider).fetchMyPosts(page: 1);
  return page.items;
});

/// 指定用户已发布动态（page=1）；随 [ucgPostsChangedProvider] 刷新。
final ucgUserPostsProvider = FutureProvider.autoDispose
    .family<List<UcgPost>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  ref.watch(ucgPostsChangedProvider);
  final page =
      await ref.read(ucgRepositoryProvider).fetchUserPosts(wxId: userId, page: 1);
  return page.items;
});

/// 已登录用户的 UCG「我的」资料：有 wxId 时走 `/profile/me`；设备态用喂养宝宝信息兜底展示。
final ucgMyProfileProvider = FutureProvider.autoDispose<UcgProfile?>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) return null;
  // 宝宝昵称变更时同步刷新展示（与母婴模块一致）。
  ref.watch(settingsBabyProvider);
  // 随 JWT sub 变化重新拉取（登录/刷新后 wxId 才可用）。
  final wxId = ref.watch(ucgCurrentUserIdProvider);
  if (!isUcgWxAccountBound(wxId)) {
    return _fallbackUcgProfileFromFeeding(ref);
  }
  final fetched = await ref.read(ucgRepositoryProvider).fetchMyProfile();
  if (fetched == null || fetched.userId.isEmpty) {
    return _fallbackUcgProfileFromFeeding(ref, wxId: wxId);
  }
  var current = fetched;
  if (current.postCount <= 0) {
    try {
      final posts = await ref.read(ucgRepositoryProvider).fetchMyPosts(page: 1);
      current = current.copyWith(postCount: posts.total);
    } catch (_) {}
  }
  if (current.followingCount <= 0) {
    try {
      final following = await ref.read(ucgRepositoryProvider).fetchFollowingList();
      if (following.isNotEmpty) {
        current = current.copyWith(followingCount: following.length);
      }
    } catch (_) {}
  }
  return current;
});

Future<UcgProfile> _fallbackUcgProfileFromFeeding(
  Ref ref, {
  String? wxId,
}) async {
  final baby = await ref.read(settingsBabyProvider.future);
  final name = baby.nickname.trim();
  final nickname = (name.isEmpty || name == '未绑定宝宝ID') ? '家长' : '$name的家长';
  return UcgProfile(
    userId: wxId ?? '0',
    nickname: nickname,
  );
}
