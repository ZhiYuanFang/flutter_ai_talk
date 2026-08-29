import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feature_unlock_models.dart';
import 'feature_unlock_provider.dart';

/// 我的邀请码（懒 Ensure）。
final inviteMineProvider = FutureProvider.autoDispose<InviteMine>((ref) {
  return ref.watch(featureUnlockRepositoryProvider).fetchInviteMine();
});

/// 成功使用我码的用户列表。
final inviteInviteesProvider =
    FutureProvider.autoDispose<List<InviteInvitee>>((ref) {
  return ref.watch(featureUnlockRepositoryProvider).fetchInviteInvitees();
});
