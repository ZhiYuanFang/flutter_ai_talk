import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_account_profile.dart';
import 'repositories.dart';
import 'session_provider.dart';

final userProfileProvider = FutureProvider<UserAccountProfile>((ref) async {
  if (!ref.watch(sessionProvider).isLoggedIn) {
    throw StateError('未登录');
  }
  return ref.read(authRepositoryProvider).fetchUserProfile();
});
