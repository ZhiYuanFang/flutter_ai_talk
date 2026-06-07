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
  );
  ref.onDispose(repo.dispose);
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

/// 消息会话列表；离开聊天页或进入消息 Tab 时随 [ucgConversationsChangedProvider] 刷新。
final ucgConversationsProvider = FutureProvider.autoDispose<List<UcgConversation>>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) return [];
  final wxId = ref.watch(ucgCurrentUserIdProvider);
  if (!isUcgWxAccountBound(wxId)) return [];
  ref.watch(ucgConversationsChangedProvider);
  final repo = ref.read(ucgRepositoryProvider);
  final list = await repo.fetchConversations();
  return repo.enrichConversationsWithPeerProfiles(list);
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
