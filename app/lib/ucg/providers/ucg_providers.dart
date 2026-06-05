import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authorized_api_client_provider.dart';
import '../../providers/session_provider.dart';
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

final ucgCurrentUserIdProvider = StateProvider<String?>((ref) => null);

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
  final profile = await ref.watch(ucgRepositoryProvider).fetchMyProfile();
  if (profile != null && profile.userId.isNotEmpty) {
    ref.read(ucgCurrentUserIdProvider.notifier).state = profile.userId;
  }
  return profile;
});
