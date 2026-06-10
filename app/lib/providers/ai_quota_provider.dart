import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import '../data/ai_quota_models.dart';
import '../session/token_expiry.dart';
import 'authorized_api_client_provider.dart';
import 'session_provider.dart';

/// 当前登录且已绑定微信账号（wxId>0）时的 AI 月度额度；失败或未登录返回 null。
final aiQuotaStatusProvider = FutureProvider.autoDispose<AiQuotaStatus?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return null;
  final wxId = readJwtWxId(session.accessToken);
  if (!isUcgWxAccountBound(wxId)) return null;

  final api = ref.watch(authorizedApiClientProvider);
  try {
    final data = await api.getEnvelope('/device/app/api/ai-quota');
    if (data == null) return null;
    return AiQuotaStatus.fromJson(data);
  } on ApiBusinessException {
    return null;
  }
});
