import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import '../data/ai_quota_models.dart';
import '../session/token_expiry.dart';
import 'authorized_api_client_provider.dart';
import 'session_provider.dart';

/// 喂养 AI + 胖宝 AI 月度额度（`GET /voice/app/api/ai-quota`）。
final voiceAiQuotaProvider = FutureProvider.autoDispose<VoiceAiQuotaStatus?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return null;
  final wxId = readJwtWxId(session.accessToken);
  if (!isUcgWxAccountBound(wxId)) return null;

  final api = ref.watch(authorizedApiClientProvider);
  try {
    final data = await api.getEnvelope('/voice/app/api/ai-quota');
    if (data == null) return null;
    return VoiceAiQuotaStatus.fromJson(data);
  } on ApiBusinessException {
    return null;
  }
});

/// 润笔 AI 月度额度（`GET /ucg/app/api/ai-quota`）。
final polishAiQuotaProvider = FutureProvider.autoDispose<PolishAiQuotaStatus?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return null;
  final wxId = readJwtWxId(session.accessToken);
  if (!isUcgWxAccountBound(wxId)) return null;

  final api = ref.watch(authorizedApiClientProvider);
  try {
    final data = await api.getEnvelope('/ucg/app/api/ai-quota');
    if (data == null) return null;
    return PolishAiQuotaStatus.fromJson(data);
  } on ApiBusinessException {
    return null;
  }
});
