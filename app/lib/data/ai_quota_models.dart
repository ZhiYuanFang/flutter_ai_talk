/// 单 feature 用量快照（voice / ucg 分域 API 共用）。
library;

class AiQuotaFeatureStatus {

  const AiQuotaFeatureStatus({
    required this.used,
    required this.limit,
    this.degraded = false,
  });



  final int used;

  final int limit;

  /// 额度用尽且服务端允许降速 fallback（polish / clinic_ai）。
  final bool degraded;



  int get remaining => (limit - used).clamp(0, limit);



  factory AiQuotaFeatureStatus.fromJson(Map<String, dynamic> json) {

    final usedVal = json['used'];

    final limitVal = json['limit'];

    return AiQuotaFeatureStatus(

      used: usedVal is int ? usedVal : (usedVal is num ? usedVal.toInt() : 0),

      limit: limitVal is int ? limitVal : (limitVal is num ? limitVal.toInt() : 0),

      degraded: json['degraded'] == true,

    );

  }

}



/// `GET /voice/app/api/ai-quota` 响应。

class VoiceAiQuotaStatus {

  const VoiceAiQuotaStatus({required this.voiceAi, required this.clinicAi});



  final AiQuotaFeatureStatus voiceAi;

  final AiQuotaFeatureStatus clinicAi;



  factory VoiceAiQuotaStatus.fromJson(Map<String, dynamic> json) {

    final voiceRaw = json['voiceAi'];

    final clinicRaw = json['clinicAi'];

    return VoiceAiQuotaStatus(

      voiceAi: voiceRaw is Map<String, dynamic>

          ? AiQuotaFeatureStatus.fromJson(voiceRaw)

          : const AiQuotaFeatureStatus(used: 0, limit: 0),

      clinicAi: clinicRaw is Map<String, dynamic>

          ? AiQuotaFeatureStatus.fromJson(clinicRaw)

          : const AiQuotaFeatureStatus(used: 0, limit: 0),

    );

  }

}



/// `GET /ucg/app/api/ai-quota` 响应。

class PolishAiQuotaStatus {

  const PolishAiQuotaStatus({required this.polish});



  final AiQuotaFeatureStatus polish;



  factory PolishAiQuotaStatus.fromJson(Map<String, dynamic> json) {

    final polishRaw = json['polish'];

    return PolishAiQuotaStatus(

      polish: polishRaw is Map<String, dynamic>

          ? AiQuotaFeatureStatus.fromJson(polishRaw)

          : const AiQuotaFeatureStatus(used: 0, limit: 0),

    );

  }

}
