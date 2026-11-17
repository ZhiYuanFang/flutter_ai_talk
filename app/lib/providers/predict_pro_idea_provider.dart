import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import '../data/client_usage_events.dart';
import '../data/predict_pro_idea_models.dart';
import '../data/predict_pro_idea_repository.dart';
import 'authorized_api_client_provider.dart';
import 'client_usage_provider.dart';
import 'toast_bus.dart';

final predictProIdeaRepositoryProvider = Provider<PredictProIdeaRepository>((ref) {
  return PredictProIdeaRepository(ref.watch(authorizedApiClientProvider));
});

/// 墙内想法列表状态。
class PredictProIdeaListState {
  const PredictProIdeaListState({
    this.items = const [],
    this.loading = false,
    this.loaded = false,
    this.errorMessage,
  });

  final List<PredictProIdeaItem> items;
  final bool loading;
  final bool loaded;
  final String? errorMessage;

  PredictProIdeaListState copyWith({
    List<PredictProIdeaItem>? items,
    bool? loading,
    bool? loaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PredictProIdeaListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final predictProIdeaListProvider =
    StateNotifierProvider<PredictProIdeaListNotifier, PredictProIdeaListState>(
  (ref) => PredictProIdeaListNotifier(ref),
);

class PredictProIdeaListNotifier extends StateNotifier<PredictProIdeaListState> {
  PredictProIdeaListNotifier(this._ref) : super(const PredictProIdeaListState());

  final Ref _ref;
  Future<void>? _loadInFlight;

  PredictProIdeaRepository get _repo =>
      _ref.read(predictProIdeaRepositoryProvider);

  /// 进墙预热：single-flight；每次拉网（不再因已 loaded 短路，避免服务端已空仍留旧列表）。
  /// [force] 保留兼容；与是否已 loaded 无关，仅 in-flight 复用。
  Future<void> ensureLoaded({bool force = false}) {
    final existing = _loadInFlight;
    if (existing != null) return existing;
    final fut = _doLoad();
    _loadInFlight = fut.whenComplete(() => _loadInFlight = null);
    return _loadInFlight!;
  }

  Future<void> refresh() => ensureLoaded(force: true);

  Future<void> _doLoad() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await _repo.list();
      if (!mounted) return;
      // 成功必须整表替换：含 []，禁止「空结果直接过」保留旧 items
      state = PredictProIdeaListState(
        items: List<PredictProIdeaItem>.of(items),
        loading: false,
        loaded: true,
      );
    } on ApiBusinessException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        loaded: true,
        errorMessage: e.message,
        items: state.items,
      );
    } on ApiHttpException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        loaded: true,
        errorMessage: '网络错误(${e.statusCode})',
        items: state.items,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        loaded: true,
        errorMessage: '加载失败',
        items: state.items,
      );
    }
  }

  /// 提交成功后刷新列表；错误已 toast。
  Future<bool> submit(String text) async {
    final t = text.trim();
    if (t.isEmpty) return false;
    try {
      await _repo.submit(t);
      await refresh();
      // 提交成功：行为日志（静默、不挡 UI）
      unawaited(
        _ref
            .read(clientUsageReporterProvider)
            .reportEvent(ClientUsageEvents.predictProIdeaSubmit),
      );
      return true;
    } on ApiBusinessException catch (e) {
      _ref.showApiToastError(e.message);
      return false;
    } on ApiHttpException catch (e) {
      _ref.showApiToastError('网络错误(${e.statusCode})');
      return false;
    } catch (_) {
      _ref.showApiToastError('提交失败，请稍后重试');
      return false;
    }
  }

  /// 作者删除；成功后本地移除并上报。
  Future<bool> deleteIdea(int id) async {
    try {
      await _repo.delete(id);
      if (!mounted) return true;
      final next = state.items.where((e) => e.id != id).toList(growable: false);
      state = state.copyWith(items: next);
      unawaited(
        _ref
            .read(clientUsageReporterProvider)
            .reportEvent(ClientUsageEvents.predictProIdeaDelete),
      );
      return true;
    } on ApiBusinessException catch (e) {
      _ref.showApiToastError(e.message);
      return false;
    } on ApiHttpException catch (e) {
      _ref.showApiToastError('网络错误(${e.statusCode})');
      return false;
    } catch (_) {
      _ref.showApiToastError('删除失败，请稍后重试');
      return false;
    }
  }

  /// 切换点赞；乐观更新，失败回滚。
  Future<void> toggleLike(int id) async {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = state.items[idx];
    final nextLiked = !cur.likedByMe;
    final optimistic = cur.copyWith(
      likedByMe: nextLiked,
      likeCount: (cur.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 30),
    );
    final before = List<PredictProIdeaItem>.from(state.items);
    final after = List<PredictProIdeaItem>.from(state.items);
    after[idx] = optimistic;
    state = state.copyWith(items: after);

    try {
      final res = nextLiked
          ? await _repo.like(id)
          : await _repo.unlike(id);
      if (!mounted) return;
      final i2 = state.items.indexWhere((e) => e.id == id);
      if (i2 < 0) return;
      final synced = List<PredictProIdeaItem>.from(state.items);
      synced[i2] = state.items[i2].copyWith(
        likeCount: res.likeCount,
        likedByMe: res.likedByMe,
      );
      state = state.copyWith(items: synced);
      // 赞/取消赞成功后分 featureId 上报
      unawaited(
        _ref.read(clientUsageReporterProvider).reportEvent(
              nextLiked
                  ? ClientUsageEvents.predictProIdeaLike
                  : ClientUsageEvents.predictProIdeaUnlike,
            ),
      );
    } on ApiBusinessException catch (e) {
      if (!mounted) return;
      state = state.copyWith(items: before);
      _ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      if (!mounted) return;
      state = state.copyWith(items: before);
      _ref.showApiToastError('网络错误(${e.statusCode})');
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(items: before);
      _ref.showApiToastError('操作失败，请稍后重试');
    }
  }
}
