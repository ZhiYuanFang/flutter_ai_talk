/// `GET /device/app/api/ai-quota` 单 feature 用量快照。
class AiQuotaFeatureStatus {
  const AiQuotaFeatureStatus({required this.used, required this.limit});

  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);

  factory AiQuotaFeatureStatus.fromJson(Map<String, dynamic> json) {
    final usedVal = json['used'];
    final limitVal = json['limit'];
    return AiQuotaFeatureStatus(
      used: usedVal is int ? usedVal : (usedVal is num ? usedVal.toInt() : 0),
      limit: limitVal is int ? limitVal : (limitVal is num ? limitVal.toInt() : 0),
    );
  }
}

/// App 读 API 完整响应。
class AiQuotaStatus {
  const AiQuotaStatus({required this.polish, required this.voiceAi});

  final AiQuotaFeatureStatus polish;
  final AiQuotaFeatureStatus voiceAi;

  factory AiQuotaStatus.fromJson(Map<String, dynamic> json) {
    final polishRaw = json['polish'];
    final voiceRaw = json['voiceAi'];
    return AiQuotaStatus(
      polish: polishRaw is Map<String, dynamic>
          ? AiQuotaFeatureStatus.fromJson(polishRaw)
          : const AiQuotaFeatureStatus(used: 0, limit: 0),
      voiceAi: voiceRaw is Map<String, dynamic>
          ? AiQuotaFeatureStatus.fromJson(voiceRaw)
          : const AiQuotaFeatureStatus(used: 0, limit: 0),
    );
  }
}
