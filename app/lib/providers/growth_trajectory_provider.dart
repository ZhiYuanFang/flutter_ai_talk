import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../data/feature_unlock_models.dart';
import '../data/growth_trajectory_models.dart';
import '../data/growth_trajectory_repository.dart';
import '../util/thinking_stage_delta.dart';
import 'authorized_api_client_provider.dart';
import 'cash_vip_provider.dart';
import 'device_no_notifier.dart';
import 'feature_unlock_provider.dart';

final growthTrajectoryRepositoryProvider =
    Provider<GrowthTrajectoryRepository>((ref) {
  return GrowthTrajectoryRepository(ref.watch(authorizedApiClientProvider));
});

/// 卡片会话阶段。
enum GrowthTrajectoryPhase {
  idle,
  loadingLatest,
  streaming,
  asking,
  ready,
}

class GrowthTrajectoryUiState {
  const GrowthTrajectoryUiState({
    this.phase = GrowthTrajectoryPhase.idle,
    this.resultMarkdown = '',
    this.thinking = '',
    this.showThinking = false,
    this.question,
    this.sessionId = '',
    this.errorMessage = '',
    this.latestLoaded = false,
    this.usedToday = 0,
    this.dailyLimit = 5,
  });

  final GrowthTrajectoryPhase phase;
  final String resultMarkdown;
  final String thinking;
  final bool showThinking;
  final GrowthTrajectoryQuestion? question;
  final String sessionId;
  final String errorMessage;
  final bool latestLoaded;
  final int usedToday;
  final int dailyLimit;

  bool get hasResult => resultMarkdown.trim().isNotEmpty;

  /// 已开通 CTA 下方文案。
  String get usageCopy => '今日已用 $usedToday/$dailyLimit 次';

  GrowthTrajectoryUiState copyWith({
    GrowthTrajectoryPhase? phase,
    String? resultMarkdown,
    String? thinking,
    bool? showThinking,
    GrowthTrajectoryQuestion? question,
    bool clearQuestion = false,
    String? sessionId,
    String? errorMessage,
    bool? latestLoaded,
    int? usedToday,
    int? dailyLimit,
  }) {
    return GrowthTrajectoryUiState(
      phase: phase ?? this.phase,
      resultMarkdown: resultMarkdown ?? this.resultMarkdown,
      thinking: thinking ?? this.thinking,
      showThinking: showThinking ?? this.showThinking,
      question: clearQuestion ? null : (question ?? this.question),
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage ?? this.errorMessage,
      latestLoaded: latestLoaded ?? this.latestLoaded,
      usedToday: usedToday ?? this.usedToday,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}

class GrowthTrajectoryNotifier extends StateNotifier<GrowthTrajectoryUiState> {
  GrowthTrajectoryNotifier(this._ref) : super(const GrowthTrajectoryUiState()) {
    _ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      final a = prev?.asData?.value?.trim() ?? '';
      final b = next.asData?.value?.trim() ?? '';
      if (a != b) clear();
    });
  }

  final Ref _ref;
  Future<void>? _inFlight;

  void clear() {
    state = const GrowthTrajectoryUiState();
  }

  String? _deviceNo() =>
      _ref.read(deviceNoNotifierProvider).asData?.value?.trim();

  bool get isEffectivelyUnlocked {
    final isVip = _ref.read(vipStatusProvider).valueOrNull?.isVip == true;
    final item = _ref
        .read(featureCatalogStateProvider)
        .byId(kFeatureIdGrowthTrajectoryPredict);
    return isFeatureEffectivelyUnlocked(item: item, isVip: isVip);
  }

  /// 与进页门闸一致：已开通 / VIP / 试用可进详情。
  bool get canAccessGrowthDetail {
    final isVip = _ref.read(vipStatusProvider).valueOrNull?.isVip == true;
    final item = _ref
        .read(featureCatalogStateProvider)
        .byId(kFeatureIdGrowthTrajectoryPredict);
    return canAccessFeatureDetail(item: item, isVip: isVip);
  }

  /// 进页拉最新结果；内存中已有追问/流式时 MUST 保题，不得因开通抖动清掉。
  Future<void> ensureLatest({bool force = false}) async {
    // 先保题：asking / streaming 一律不拉 latest、不改 phase
    if (state.phase == GrowthTrajectoryPhase.streaming ||
        state.phase == GrowthTrajectoryPhase.asking) {
      return;
    }

    // 与页面 canAccess 对齐（含试用）；不可进时也不要强行 idle 冲掉其它态
    if (!canAccessGrowthDetail) {
      state = state.copyWith(latestLoaded: true);
      return;
    }
    if (state.latestLoaded && !force) return;

    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
    }
    final deviceNo = _deviceNo();
    if (deviceNo == null || deviceNo.isEmpty) {
      state = state.copyWith(latestLoaded: true);
      return;
    }

    state = state.copyWith(
      phase: GrowthTrajectoryPhase.loadingLatest,
      errorMessage: '',
    );
    try {
      final latest = await _ref
          .read(growthTrajectoryRepositoryProvider)
          .fetchLatest(deviceNo: deviceNo);
      // 异步返回前若已进入追问/流式，放弃覆盖
      if (state.phase == GrowthTrajectoryPhase.streaming ||
          state.phase == GrowthTrajectoryPhase.asking) {
        return;
      }
      final md = latest?.resultMarkdown?.trim() ?? '';
      state = state.copyWith(
        phase: md.isNotEmpty
            ? GrowthTrajectoryPhase.ready
            : GrowthTrajectoryPhase.idle,
        resultMarkdown: md,
        sessionId: latest?.sessionId ?? '',
        usedToday: latest?.usedToday ?? 0,
        dailyLimit: latest?.dailyLimit ?? 5,
        latestLoaded: true,
        showThinking: false,
        thinking: '',
        clearQuestion: true,
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.growthTrajectory('ensureLatest business ${e.message}');
      if (state.phase == GrowthTrajectoryPhase.streaming ||
          state.phase == GrowthTrajectoryPhase.asking) {
        return;
      }
      state = state.copyWith(
        phase: GrowthTrajectoryPhase.idle,
        latestLoaded: true,
        errorMessage: e.message,
      );
    } catch (e) {
      AppDebugLog.growthTrajectory('ensureLatest err=$e');
      if (state.phase == GrowthTrajectoryPhase.streaming ||
          state.phase == GrowthTrajectoryPhase.asking) {
        return;
      }
      state = state.copyWith(
        phase: GrowthTrajectoryPhase.idle,
        latestLoaded: true,
      );
    }
  }

  /// 开始或重新预测。
  Future<String?> startPredict({bool restart = false}) {
    return _runTurn(
      action: restart ? 'restart' : 'start',
      sessionId: restart ? '' : state.sessionId,
    );
  }

  /// 提交问答（不计本地日次）。
  Future<String?> submitAnswer({
    required String questionId,
    required String value,
  }) {
    final v = value.trim();
    if (v.isEmpty) {
      return Future.value('请填写后再提交');
    }
    final sid = state.sessionId.trim();
    if (sid.isEmpty) {
      return Future.value('会话已失效，请重新预测');
    }
    return _runTurn(
      action: 'answer',
      sessionId: sid,
      questionId: questionId,
      answerValue: v,
    );
  }

  Future<String?> _runTurn({
    required String action,
    String sessionId = '',
    String questionId = '',
    String answerValue = '',
  }) async {
    if (_inFlight != null) {
      await _inFlight;
      return state.errorMessage.isEmpty ? null : state.errorMessage;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;
    String? errOut;

    // 提交答案失败时恢复追问（latest API 无 pending question）
    final isAnswer = action == 'answer';
    final savedQuestion = state.question;
    final savedSessionId = state.sessionId.trim();

    /// 失败回落：answer 且仍有可恢复追问 → asking；否则 idle/ready
    void applyTurnFailure(String message) {
      final canRestoreAsk = isAnswer &&
          savedQuestion != null &&
          savedSessionId.isNotEmpty;
      if (canRestoreAsk) {
        AppDebugLog.growthTrajectory('turn fail restore asking qId=${savedQuestion.id}');
        state = state.copyWith(
          phase: GrowthTrajectoryPhase.asking,
          showThinking: false,
          thinking: '',
          question: savedQuestion,
          sessionId: savedSessionId,
          errorMessage: message,
        );
        return;
      }
      state = state.copyWith(
        phase: state.hasResult
            ? GrowthTrajectoryPhase.ready
            : GrowthTrajectoryPhase.idle,
        showThinking: false,
        thinking: '',
        clearQuestion: true,
        errorMessage: message,
      );
    }

    try {
      var dn = _deviceNo();
      if (dn == null || dn.isEmpty) {
        await _ref.read(deviceNoNotifierProvider.notifier).refresh();
        dn = _deviceNo();
      }
      if (dn == null || dn.isEmpty) {
        errOut = '请先绑定宝宝信息';
        state = state.copyWith(errorMessage: errOut);
        return errOut;
      }

      state = state.copyWith(
        phase: GrowthTrajectoryPhase.streaming,
        showThinking: true,
        thinking: '',
        // answer：保留当前题直至新 question/result；start/restart 可清
        clearQuestion: !isAnswer,
        errorMessage: '',
      );

      await for (final ev in _ref
          .read(growthTrajectoryRepositoryProvider)
          .turnStream(
            deviceNo: dn,
            action: action,
            sessionId: sessionId,
            questionId: questionId,
            answerValue: answerValue,
          )) {
        switch (ev) {
          case GrowthTrajectoryThinkingDelta(:final content):
            state = state.copyWith(
              phase: GrowthTrajectoryPhase.streaming,
              showThinking: true,
              thinking: applyThinkingStageDelta(state.thinking, content),
            );
          case GrowthTrajectoryQuestionEvent(:final question):
            final sid = question.sessionId.trim().isNotEmpty
                ? question.sessionId
                : state.sessionId;
            state = state.copyWith(
              phase: GrowthTrajectoryPhase.asking,
              showThinking: false,
              thinking: '',
              question: question,
              sessionId: sid,
            );
          case GrowthTrajectoryResultEvent(
              :final markdown,
              :final sessionId,
              :final usedToday,
              :final dailyLimit,
            ):
            final sid =
                sessionId.trim().isNotEmpty ? sessionId : state.sessionId;
            state = state.copyWith(
              phase: GrowthTrajectoryPhase.ready,
              showThinking: false,
              thinking: '',
              clearQuestion: true,
              resultMarkdown: markdown,
              sessionId: sid,
              usedToday: usedToday,
              dailyLimit: dailyLimit,
              latestLoaded: true,
            );
          case GrowthTrajectoryErrorEvent(:final message):
            errOut = message.isNotEmpty ? message : '成长轨迹预测失败';
            applyTurnFailure(errOut);
          case GrowthTrajectoryDoneEvent():
            break;
        }
      }

      // 流结束仍在 streaming：answer 恢复追问，否则回落 idle/ready
      if (state.phase == GrowthTrajectoryPhase.streaming) {
        if (isAnswer &&
            savedQuestion != null &&
            savedSessionId.isNotEmpty) {
          state = state.copyWith(
            phase: GrowthTrajectoryPhase.asking,
            showThinking: false,
            thinking: '',
            question: savedQuestion,
            sessionId: savedSessionId,
          );
        } else {
          state = state.copyWith(
            phase: state.hasResult
                ? GrowthTrajectoryPhase.ready
                : GrowthTrajectoryPhase.idle,
            showThinking: false,
            thinking: '',
          );
        }
      }
    } on ApiBusinessException catch (e) {
      errOut = e.message.isNotEmpty ? e.message : '成长轨迹预测失败';
      AppDebugLog.growthTrajectory('turn business $errOut');
      applyTurnFailure(errOut);
    } catch (e) {
      errOut = '成长轨迹预测暂时不可用，请稍后再试';
      AppDebugLog.growthTrajectory('turn catch err=$e');
      applyTurnFailure(errOut);
    } finally {
      completer.complete();
      _inFlight = null;
    }
    return errOut;
  }
}

final growthTrajectoryStateProvider =
    StateNotifierProvider<GrowthTrajectoryNotifier, GrowthTrajectoryUiState>(
        (ref) {
  return GrowthTrajectoryNotifier(ref);
});
