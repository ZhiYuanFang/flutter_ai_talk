import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../data/tip_models.dart';
import '../data/tip_repository.dart';
import 'session_provider.dart';

/// 小贴士 Repository Provider
final tipRepositoryProvider = Provider<TipRepository>((ref) {
  return TipRepository(
    baseUrl: AppEnv.apiBaseUrl,
    tokenProvider: () => ref.read(sessionProvider).accessToken ?? '',
  );
});

/// 小贴士状态管理 Provider
final tipProvider = StateNotifierProvider<TipNotifier, TipContent>((ref) {
  return TipNotifier(ref);
});

class TipNotifier extends StateNotifier<TipContent> {
  final Ref _ref;

  /// 流代数：dismiss / 新 startStreaming 时递增，用于丢弃旧 SSE
  var _streamEpoch = 0;

  TipNotifier(this._ref) : super(const TipContent());

  /// 开始流式接收小贴士；重置内容并 bump presentationGeneration
  Future<void> startStreaming({
    required String deviceNo,
    required int eventId,
    required String eventName,
  }) async {
    final epoch = ++_streamEpoch;
    // 重置为 streaming，清空旧文案，入场代数 +1 供 UI 再弹
    state = TipContent(
      displayState: TipDisplayState.streaming,
      presentationGeneration: state.presentationGeneration + 1,
    );

    try {
      final repo = _ref.read(tipRepositoryProvider);
      await for (final event in repo.streamTip(
        deviceNo: deviceNo,
        eventId: eventId,
        eventName: eventName,
      )) {
        // 已关闭或已被更新的流：丢弃后续事件
        if (epoch != _streamEpoch) return;

        if (event.done) {
          state = state.copyWith(displayState: TipDisplayState.done);
          break;
        }

        if (event.type == 'done') {
          if (event.answerId != null && event.answerId!.isNotEmpty) {
            state = state.copyWith(answerId: event.answerId);
          }
          continue;
        }

        if (event.type == 'thinking') {
          state = state.copyWith(
            thinking: state.thinking + event.content,
          );
        } else if (event.type == 'answer') {
          state = state.copyWith(
            answer: state.answer + event.content,
          );
        }
      }
    } catch (e) {
      if (epoch != _streamEpoch) return;
      if (state.answer.isEmpty && state.thinking.isEmpty) {
        state = TipContent(
          presentationGeneration: state.presentationGeneration,
        );
      } else {
        state = state.copyWith(displayState: TipDisplayState.done);
      }
    }
  }

  /// 提交用户反馈
  Future<void> submitFeedback(TipFeedback feedback) async {
    final answerId = state.answerId;
    if (answerId == null || answerId.isEmpty) return;
    if (state.feedback != TipFeedback.none) return;

    state = state.copyWith(
      feedback: feedback,
      feedbackSubmitting: true,
    );

    try {
      final repo = _ref.read(tipRepositoryProvider);
      await repo.submitFeedback(
        answerId: answerId,
        feedback: feedback == TipFeedback.up ? 1 : -1,
      );
    } finally {
      state = state.copyWith(feedbackSubmitting: false);
    }
  }

  /// 关闭面板：streaming / done 均可；作废当前 SSE，立即回 idle
  void dismiss() {
    final ds = state.displayState;
    if (ds != TipDisplayState.streaming && ds != TipDisplayState.done) {
      return;
    }
    _streamEpoch++;
    state = TipContent(
      presentationGeneration: state.presentationGeneration,
    );
  }

  /// 兼容旧 UI 调用；当前等同清空
  void completeDismiss() {
    state = TipContent(
      presentationGeneration: state.presentationGeneration,
    );
  }

  void reset() {
    _streamEpoch++;
    state = const TipContent();
  }

  void markConsumedForCompanion() {
    if (state.consumedForCompanion) return;
    state = state.copyWith(consumedForCompanion: true);
  }

  void resetCompanionConsumption() {
    if (!state.consumedForCompanion) return;
    state = state.copyWith(consumedForCompanion: false);
  }
}
