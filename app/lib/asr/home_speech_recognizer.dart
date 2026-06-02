/// 云端 PCM 录音诊断（块级 / 会话 avgAbs）。
typedef PcmDiagnosticsCallback = void Function({
  required int chunkAvgAbs,
  required int sessionAvgAbs,
});

/// 主页按住说话用的语音识别抽象。
abstract class HomeSpeechRecognizer {
  /// 懒加载引擎/模型；返回是否可用。
  Future<bool> prepare();

  /// 开始一次采集（按住）。
  /// [onLevel] 归一化响度 0..1，可选。
  Future<void> startSession(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    PcmDiagnosticsCallback? onPcmDiagnostics,
  });

  /// 结束采集（松手），返回最终转写文本（可为空）。
  Future<String> endSession();

  /// 取消采集（指针取消等）。
  Future<void> cancelSession();

  void dispose();

  /// 最近一次 [prepare] 失败原因（若实现类支持）。
  HomeSpeechPrepareFailure? get lastPrepareFailure => null;
}

/// 用户可读的失败原因（模型缺失、权限等）。
enum HomeSpeechPrepareFailure {
  modelMissing,
  permissionDenied,
  engineError,
  voiceWsDisconnected,
}

extension HomeSpeechPrepareFailureMessage on HomeSpeechPrepareFailure {
  String message({required bool forWeb}) => switch (this) {
        HomeSpeechPrepareFailure.modelMissing => forWeb
            ? '语音识别资源未就绪，请稍后重试或改用文字输入'
            : '语音识别资源未就绪，请稍后重试或切换到事件记录模式',
        HomeSpeechPrepareFailure.permissionDenied => '需要麦克风权限才能使用语音输入',
        HomeSpeechPrepareFailure.voiceWsDisconnected =>
          '语音转写服务未连接，请稍候再按或检查网络',
        HomeSpeechPrepareFailure.engineError => forWeb
            ? '语音识别初始化失败，请改用文字输入'
            : '语音识别初始化失败，请切换到事件记录模式',
      };
}
