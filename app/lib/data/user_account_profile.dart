import 'package:flutter/foundation.dart';

import '../api/gateway_json.dart';

@immutable
class UserAccountProfile {
  const UserAccountProfile({
    required this.account,
    required this.isWxBound,
    required this.isAppleBound,
    required this.authProviders,
  });

  final String account;
  final bool isWxBound;
  final bool isAppleBound;
  final List<String> authProviders;

  bool get hasAccount => account.isNotEmpty;

  factory UserAccountProfile.fromGateway(Map<String, dynamic> data) {
    final rawAccount = readGatewayStr(data, 'account', 'account') ?? '';
    final wx = data['isWxBound'] ?? data['is_wx_bound'];
    final isWxBound = wx == true || wx == 1 || (wx is String && wx.toLowerCase() == 'true');
    final apple = data['isAppleBound'] ?? data['is_apple_bound'];
    final isAppleBound = apple == true || apple == 1 || (apple is String && apple.toLowerCase() == 'true');
    final rawProviders = data['authProviders'] ?? data['auth_providers'];
    final providers = <String>[];
    if (rawProviders is List) {
      for (final item in rawProviders) {
        final s = item?.toString().trim() ?? '';
        if (s.isNotEmpty) providers.add(s);
      }
    }
    return UserAccountProfile(
      account: rawAccount.trim().toLowerCase(),
      isWxBound: isWxBound,
      isAppleBound: isAppleBound,
      authProviders: providers,
    );
  }
}
