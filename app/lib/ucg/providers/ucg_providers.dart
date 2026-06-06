import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authorized_api_client_provider.dart';
import '../../providers/session_provider.dart';
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

final ucgMyProfileProvider = FutureProvider.autoDispose<UcgProfile?>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) return null;
  return ref.watch(ucgRepositoryProvider).fetchMyProfile();
});
