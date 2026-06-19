import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authorized_api_client_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_baby.dart';
import '../../session/token_expiry.dart';
import '../data/ucg_api_client.dart';
import '../data/ucg_compose_draft_store.dart';
import '../data/ucg_models.dart';
import '../data/ucg_repository.dart';

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
  );
  ref.onDispose(repo.dispose);

  void syncUcgWsDesired() {
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (loggedIn && isUcgWxAccountBound(wxId)) {
      repo.setWsConnectionDesired(true);
    } else {
      repo.setWsConnectionDesired(false);
    }
  }

  Future<void> syncUnreadFromWs() async {
    if (!ref.read(sessionProvider).isLoggedIn) return;
    if (!isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider))) return;
    try {
      final notifPage = await repo.fetchCommentNotifications(page: 1);
      final convPage = await repo.fetchConversations(page: 1);
      final chatUnread = convPage.items.fold<int>(0, (s, c) => s + c.unreadCount);
      ref.read(ucgUnreadCountProvider.notifier).state =
          chatUnread + notifPage.unreadCount;
    } catch (_) {}
  }

  ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
    syncUcgWsDesired();
    if (loggedIn) {
      unawaited(syncUnreadFromWs());
    } else {
      ref.read(ucgUnreadCountProvider.notifier).state = 0;
    }
  });
  ref.listen<String?>(ucgCurrentUserIdProvider, (_, __) {
    syncUcgWsDesired();
    unawaited(syncUnreadFromWs());
  });
  syncUcgWsDesired();
  unawaited(syncUnreadFromWs());

  final notifSub = repo.notificationEvents.listen((_) {
    ref.read(ucgNotificationsChangedProvider.notifier).state++;
    unawaited(syncUnreadFromWs());
  });
  final msgSub = repo.incomingMessages.listen((_) {
    unawaited(syncUnreadFromWs());
  });
  ref.onDispose(() {
    notifSub.cancel();
    msgSub.cancel();
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
  return ref.read(ucgRepositoryProvider).fetchPost(postId);
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
