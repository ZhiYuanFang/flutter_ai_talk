import '../api/api_client.dart';
import '../api/app_debug_log.dart';

/// 满意度问卷当前活动。只在 [show] 为 true 时弹出。
class SatisfactionSurveyCurrent {
  const SatisfactionSurveyCurrent({
    required this.show,
    required this.campaignId,
    required this.intro,
    required this.options,
  });

  final bool show;
  final int campaignId;
  final String intro;
  final List<SatisfactionSurveyOption> options;

  factory SatisfactionSurveyCurrent.fromJson(Map<String, dynamic> data) {
    final raw = data['options'];
    final options = <SatisfactionSurveyOption>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final idRaw = map['id'];
        final id = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0;
        if (id < 1) continue;
        options.add(
          SatisfactionSurveyOption(
            id: id,
            text: (map['text'] as String?)?.trim() ?? '',
          ),
        );
      }
    }
    final campRaw = data['campaignId'];
    final campaignId =
        campRaw is num ? campRaw.toInt() : int.tryParse('$campRaw') ?? 0;
    return SatisfactionSurveyCurrent(
      show: data['show'] == true,
      campaignId: campaignId < 0 ? 0 : campaignId,
      intro: (data['intro'] as String?)?.trim() ?? '',
      options: options,
    );
  }
}

/// 启用中的选项。
class SatisfactionSurveyOption {
  const SatisfactionSurveyOption({required this.id, required this.text});

  final int id;
  final String text;
}

/// 满意度问卷：`GET/POST /device/app/api/survey/*`。不在客户端比较有效期。
class SatisfactionSurveyRepository {
  SatisfactionSurveyRepository(this._api);

  final ApiClient _api;

  static const currentPath = '/device/app/api/survey/current';
  static const submitPath = '/device/app/api/survey/submit';

  /// 读取是否展示。失败由调用方记日志，这里不吞异常。
  Future<SatisfactionSurveyCurrent> fetchCurrent() async {
    final data = await _api.getEnvelope(currentPath);
    final current = SatisfactionSurveyCurrent.fromJson(data ?? const {});
    AppDebugLog.survey(
      'current show=${current.show} campaignId=${current.campaignId} options=${current.options.length}',
    );
    return current;
  }

  /// 提交拼好的选项结果。空 data 也算成功。重复提交由服务端保持单行并成功。
  Future<void> submit({
    required int campaignId,
    required List<String> optionResults,
    required String comment,
  }) async {
    await _api.postJsonEnvelope(submitPath, {
      'campaignId': campaignId,
      'optionResults': optionResults,
      'comment': comment,
    });
    AppDebugLog.survey(
      'submit ok campaignId=$campaignId results=${optionResults.length}',
    );
  }
}
