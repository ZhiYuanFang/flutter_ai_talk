import 'package:flutter/foundation.dart';

import '../api/gateway_json.dart';

@immutable
class UserAccountProfile {
  const UserAccountProfile({
    required this.account,
    required this.isWxBound,
  });

  final String account;
  final bool isWxBound;

  bool get hasAccount => account.isNotEmpty;

  factory UserAccountProfile.fromGateway(Map<String, dynamic> data) {
    final rawAccount = readGatewayStr(data, 'account', 'account') ?? '';
    final wx = data['isWxBound'] ?? data['is_wx_bound'];
    final isWxBound = wx == true || wx == 1 || (wx is String && wx.toLowerCase() == 'true');
    return UserAccountProfile(
      account: rawAccount.trim().toLowerCase(),
      isWxBound: isWxBound,
    );
  }
}
