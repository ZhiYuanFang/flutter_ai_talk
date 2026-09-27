import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../asr/home_speech_factory.dart';
import '../asr/home_speech_recognizer.dart';
import '../audio/voice_level_smoother.dart';
import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/growth_trajectory_provider.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import '../voice/voice_asr_ws_client.dart';
import 'ai_analysis_unlock.dart';
import 'widgets/ai_thinking_pane.dart';
import 'widgets/analysis_wait_callout.dart';
import 'widgets/app_toast.dart';
import 'widgets/clinic_answer_body.dart';
import 'widgets/feature_logo.dart';
import 'widgets/voice_level_bars.dart';

/// 成长轨迹工作台：无卡片；正文下 CTA；功能色渐变底。
class GrowthTrajectoryScreen extends ConsumerStatefulWidget {
  const GrowthTrajectoryScreen({super.key});

  @override
  ConsumerState<GrowthTrajectoryScreen> createState() =>
      _GrowthTrajectoryScreenState();
}

class _GrowthTrajectoryScreenState
    extends ConsumerState<GrowthTrajectoryScreen> {
  final _freeTextController = TextEditingController();
  /// 追问框滚动：语音/程序写入时跟底
  final _askScrollController = ScrollController();
  /// choice 题：展开「手动输入」时隐藏双按钮
  bool _choiceManualMode = false;

  /// 共用全局 ASR 的按住说话（对齐伴侣页，松手只填框不提交）
  HomeSpeechRecognizer? _recognizer;
  SpeechEngine? _speechEngine;
  var _voiceReady = false;
  var _voiceAsrReady = false;
  var _voiceAsrConnecting = false;
  StreamSubscription<bool>? _voiceAsrReadySub;
  var _listening = false;
  var _partial = '';
  var _activeVoicePointer = false;
  var _slideToCancel = false;
  double? _holdStartGlobalY;
  var _voiceHoldSeq = 0;
  /// 按下前输入框快照，取消时恢复
  String _textBeforeHold = '';

  /// 按住说话能量条（平滑后驱动 VoiceLevelBars）
  late final ValueNotifier<double> _voiceLevelNotifier;
  late final VoiceLevelSmoother _voiceLevelSmoother;

  static const _slideCancelDy = 64.0;
  /// 追问输入最大高度（逻辑像素）
  static const _askFieldMaxHeight = 120.0;

  /// choice 选项：圆角矩形
  static final _choiceButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );

  @override
  void initState() {
    super.initState();
    _voiceLevelNotifier = ValueNotifier(0);
    _voiceLevelSmoother = VoiceLevelSmoother(_voiceLevelNotifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
      unawaited(_bindVoiceAsrReadyListener());
      final isVip = ref.read(vipStatusProvider).valueOrNull?.isVip == true;
      final feature = ref
          .read(featureCatalogStateProvider)
          .byId(kFeatureIdGrowthTrajectoryPredict);
      if (isFeatureEffectivelyUnlocked(item: feature, isVip: isVip) ||
          canAccessFeatureDetail(item: feature, isVip: isVip)) {
        unawaited(
          ref.read(growthTrajectoryStateProvider.notifier).ensureLatest(),
        );
      }
    });
  }

  @override
  void dispose() {
    unawaited(_voiceAsrReadySub?.cancel());
    unawaited(_cancelVoiceSession());
    _recognizer?.dispose();
    _voiceLevelNotifier.dispose();
    _askScrollController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  /// 语音/程序写入后把输入框滚到底（不抢用户上翻，仅写入路径调用）
  void _scrollAskFieldToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_askScrollController.hasClients) return;
      final max = _askScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      _askScrollController.jumpTo(max);
    });
  }

  /// 写入追问框并跟底
  void _setAskTextFollowBottom(String text) {
    _freeTextController.text = text;
    _freeTextController.selection =
        TextSelection.collapsed(offset: text.length);
    _scrollAskFieldToBottom();
  }

  void _collapseChoiceManual() {
    if (!_choiceManualMode && _freeTextController.text.isEmpty) return;
    _choiceManualMode = false;
    _freeTextController.clear();
  }

  Future<void> _toastIfErr(String? err) async {
    if (!mounted || err == null || err.isEmpty) return;
    showAppToast(err, tone: AppToastTone.error);
  }

  /// 订阅全局 ASR ready（轨迹页可能未经过首页建连）
  Future<void> _bindVoiceAsrReadyListener() async {
    await _voiceAsrReadySub?.cancel();
    _voiceAsrReadySub = null;
    if (kIsWeb) {
      if (mounted) setState(() => _voiceAsrReady = true);
      return;
    }
    final engine = await SpeechEngineStore.load();
    _speechEngine = engine;
    if (engine != SpeechEngine.cloudAsr) {
      if (mounted) setState(() => _voiceAsrReady = true);
      return;
    }
    final client = ref.read(voiceAsrWsClientProvider);
    _voiceAsrReady = client.isReady;
    _voiceAsrReadySub = client.readyStream.listen((v) {
      if (mounted) setState(() => _voiceAsrReady = v);
    });
    if (mounted) setState(() {});
  }

  /// 确保共用 VoiceAsrWsClient 已握手（单例，不新建）
  Future<void> _connectVoiceAsrWsIfNeeded() async {
    if (kIsWeb || _speechEngine != SpeechEngine.cloudAsr) return;
    if (_voiceAsrReady || _voiceAsrConnecting) return;
    if (!mounted) return;
    setState(() => _voiceAsrConnecting = true);
    try {
      final ok = await ref.read(voiceAsrWsClientProvider).connect();
      if (!mounted) return;
      setState(() {
        _voiceAsrReady = ok;
        _voiceAsrConnecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceAsrReady = false;
        _voiceAsrConnecting = false;
      });
    }
  }

  Future<bool> _prepareVoiceInput() async {
    if (kIsWeb) {
      if (mounted) {
        showAppToast('语音识别不可用，请改用文字输入', tone: AppToastTone.error);
      }
      return false;
    }
    try {
      final engine = await SpeechEngineStore.load();
      if (_speechEngine != engine) {
        _recognizer?.dispose();
        _recognizer = null;
        _voiceReady = false;
        _speechEngine = engine;
        await _bindVoiceAsrReadyListener();
      } else {
        _speechEngine ??= engine;
      }

      if (_speechEngine == SpeechEngine.cloudAsr && !_voiceAsrReady) {
        await _connectVoiceAsrWsIfNeeded();
        if (!_voiceAsrReady && !_voiceAsrConnecting && mounted) {
          showAppToast('语音转写未连接，请检查网络', tone: AppToastTone.error);
        }
      }

      if (_voiceReady &&
          _recognizer != null &&
          (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady)) {
        return true;
      }

      _recognizer ??= await createHomeSpeechRecognizer(ref);
      final ok = await _recognizer!.prepare();
      _voiceReady =
          ok && (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady);
      if (!ok && mounted) {
        final failure = _recognizer!.lastPrepareFailure ??
            HomeSpeechPrepareFailure.engineError;
        showAppToast(failure.message(forWeb: false), tone: AppToastTone.error);
      } else if (!_voiceReady &&
          mounted &&
          _speechEngine == SpeechEngine.cloudAsr) {
        showAppToast('语音转写服务未连接，请稍后再试', tone: AppToastTone.error);
      }
      return _voiceReady;
    } catch (_) {
      if (mounted) {
        showAppToast('语音识别初始化失败，请改用文字输入', tone: AppToastTone.error);
      }
      return false;
    }
  }

  bool _isVoiceHoldCurrent(int seq) => seq == _voiceHoldSeq;

  void _releaseVoiceHold() {
    _voiceHoldSeq++;
  }

  Future<void> _cancelVoiceSession() async {
    _releaseVoiceHold();
    _activeVoicePointer = false;
    _holdStartGlobalY = null;
    _voiceLevelSmoother.reset();
    if (_recognizer != null) {
      try {
        await _recognizer!.cancelSession();
      } catch (_) {}
    }
    if (!mounted) return;
    if (_listening || _partial.isNotEmpty || _slideToCancel) {
      setState(() {
        _listening = false;
        _partial = '';
        _slideToCancel = false;
        // 取消：恢复按下前快照
        _setAskTextFollowBottom(_textBeforeHold);
      });
    }
  }

  Future<void> _onVoicePointerDown() async {
    final seq = ++_voiceHoldSeq;
    _textBeforeHold = _freeTextController.text;
    _voiceLevelSmoother.reset();
    if (!await _prepareVoiceInput()) {
      _releaseVoiceHold();
      return;
    }
    if (!_isVoiceHoldCurrent(seq) || !mounted || _recognizer == null) return;

    setState(() {
      _listening = true;
      _partial = '';
      _slideToCancel = false;
    });
    await _recognizer!.startSession(
      (partial) {
        if (!mounted || !_isVoiceHoldCurrent(seq)) return;
        setState(() {
          _partial = partial;
          // 边说边写入输入框（前缀保留按下前文字）
          final merged = _textBeforeHold.isEmpty
              ? partial
              : '$_textBeforeHold$partial';
          _setAskTextFollowBottom(merged);
        });
      },
      onLevel: (level) {
        if (!mounted || !_isVoiceHoldCurrent(seq)) return;
        _voiceLevelSmoother.pushRaw(level);
      },
    );
    if (!_isVoiceHoldCurrent(seq) && mounted && _listening) {
      await _recognizer?.cancelSession();
      if (!mounted) return;
      _voiceLevelSmoother.reset();
      setState(() {
        _listening = false;
        _partial = '';
        _setAskTextFollowBottom(_textBeforeHold);
      });
    }
  }

  void _onHoldPointerDown(PointerDownEvent event) {
    if (kIsWeb) return;
    _activeVoicePointer = true;
    _holdStartGlobalY = event.position.dy;
    setState(() => _slideToCancel = false);
    unawaited(_onVoicePointerDown());
  }

  void _onHoldPointerMove(PointerMoveEvent event) {
    if (!_activeVoicePointer || _holdStartGlobalY == null) return;
    final cancel = (_holdStartGlobalY! - event.position.dy) >= _slideCancelDy;
    if (_slideToCancel != cancel) {
      setState(() => _slideToCancel = cancel);
    }
  }

  void _onHoldPointerUp(PointerUpEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    _holdStartGlobalY = null;
    final cancel = _slideToCancel;
    _releaseVoiceHold();
    setState(() => _slideToCancel = false);
    if (cancel) {
      unawaited(_onVoiceCancel(skipReleaseHold: true));
    } else {
      unawaited(_onVoiceEnd());
    }
  }

  void _onHoldPointerCancel(PointerCancelEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    _holdStartGlobalY = null;
    setState(() => _slideToCancel = false);
    unawaited(_onVoiceCancel());
  }

  Future<void> _onVoiceEnd() async {
    if (!_listening) {
      if (_recognizer != null) {
        await _recognizer!.cancelSession();
      }
      _voiceLevelSmoother.reset();
      if (mounted) setState(() => _partial = '');
      return;
    }
    if (_recognizer == null) return;
    final fromEngine = await _recognizer!.endSession();
    // 取引擎定稿与预览中更完整者，避免短 final 盖掉长草稿
    final spoken =
        VoiceAsrWsClient.preferRicherTranscript(fromEngine, _partial);
    if (!mounted) return;
    _voiceLevelSmoother.reset();
    setState(() {
      _listening = false;
      _partial = '';
      // 松手只填框，不自动 submit；无最大录音时长
      final merged = spoken.isEmpty
          ? _textBeforeHold
          : (_textBeforeHold.isEmpty ? spoken : '$_textBeforeHold$spoken');
      _setAskTextFollowBottom(merged);
    });
  }

  Future<void> _onVoiceCancel({bool skipReleaseHold = false}) async {
    if (!skipReleaseHold) {
      _releaseVoiceHold();
    }
    if (_recognizer != null) {
      await _recognizer!.cancelSession();
    }
    if (!mounted) return;
    _voiceLevelSmoother.reset();
    setState(() {
      _listening = false;
      _partial = '';
      _setAskTextFollowBottom(_textBeforeHold);
    });
  }

  /// 功能色浅玻璃底（输入壳 / 按住条）
  BoxDecoration _askAccentGlassDecoration({
    required Color accent,
    required ColorScheme scheme,
    required bool listening,
    required bool cancelled,
  }) {
    final surface = scheme.surface;
    Color fill;
    Color border;
    if (listening && cancelled) {
      fill = Color.lerp(surface, scheme.error, 0.18) ??
          scheme.error.withValues(alpha: 0.18);
      border = scheme.error.withValues(alpha: 0.45);
    } else if (listening) {
      fill = Color.lerp(surface, accent, 0.22) ?? accent.withValues(alpha: 0.18);
      border = accent.withValues(alpha: 0.5);
    } else {
      fill = Color.lerp(surface, accent, 0.12) ?? accent.withValues(alpha: 0.1);
      border = accent.withValues(alpha: 0.35);
    }
    return BoxDecoration(
      color: fill.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    );
  }

  /// 追问自适应 TextField：增高、封顶 120、可滚
  Widget _buildAskTextField({
    required Color accent,
    required ColorScheme scheme,
    required String hintText,
  }) {
    final deep = _gtDeepenAccent(accent);
    return Container(
      decoration: _askAccentGlassDecoration(
        accent: accent,
        scheme: scheme,
        listening: false,
        cancelled: false,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _askFieldMaxHeight),
        child: TextField(
          controller: _freeTextController,
          scrollController: _askScrollController,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: TextStyle(fontSize: 14, height: 1.35, color: deep),
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: accent.withValues(alpha: 0.45),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  /// 按住说话条：功能色浅玻璃 + 聆听时左右 VoiceLevelBars
  Widget _buildHoldToTalkBar({
    required Color accent,
    required ColorScheme scheme,
  }) {
    final label = kIsWeb
        ? '请使用文字输入'
        : (_listening
            ? (_slideToCancel ? '松开取消' : '松手填入')
            : '按住 说话');
    final deep = _gtDeepenAccent(accent);
    final holdCore = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: kIsWeb ? null : _onHoldPointerDown,
      onPointerMove: kIsWeb ? null : _onHoldPointerMove,
      onPointerUp: kIsWeb ? null : _onHoldPointerUp,
      onPointerCancel: kIsWeb ? null : _onHoldPointerCancel,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: _askAccentGlassDecoration(
          accent: accent,
          scheme: scheme,
          listening: _listening,
          cancelled: _slideToCancel,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _listening && _slideToCancel
                ? scheme.error
                : deep.withValues(alpha: 0.9),
          ),
        ),
      ),
    );

    if (!_listening) {
      return holdCore;
    }

    // 按住时左右能量柱
    return ListenableBuilder(
      listenable: _voiceLevelNotifier,
      builder: (context, _) {
        final bars = VoiceLevelBars(
          level: _voiceLevelNotifier.value,
          accent: accent,
          cancelled: _slideToCancel,
          maxBarHeight: 36,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            bars,
            const SizedBox(width: 8),
            Expanded(child: holdCore),
            const SizedBox(width: 8),
            bars,
          ],
        );
      },
    );
  }

  Future<void> _onPredict({required bool restart}) async {
    await _cancelVoiceSession();
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .startPredict(restart: restart);
    await _toastIfErr(err);
    // 试用首次成功后服务端 claim，刷新目录。
    unawaited(ref.read(featureCatalogStateProvider.notifier).refresh());
  }

  Future<void> _onChoice(String value) async {
    await _cancelVoiceSession();
    final q = ref.read(growthTrajectoryStateProvider).question;
    if (q == null) return;
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .submitAnswer(questionId: q.id, value: value);
    await _toastIfErr(err);
  }

  Future<void> _onSubmitFreeText() async {
    await _cancelVoiceSession();
    final q = ref.read(growthTrajectoryStateProvider).question;
    if (q == null) return;
    final text = _freeTextController.text;
    if (text.trim().isEmpty) {
      showAppToast('请填写后再提交', tone: AppToastTone.error);
      return;
    }
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .submitAnswer(questionId: q.id, value: text);
    if (err == null) {
      setState(_collapseChoiceManual);
    }
    await _toastIfErr(err);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final scheme = Theme.of(context).colorScheme;
    final gt = ref.watch(growthTrajectoryStateProvider);
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final feature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdGrowthTrajectoryPredict);
    final canUse = canAccessFeatureDetail(item: feature, isVip: isVip);
    final accent = resolveFeatureColor(context, feature);

    // 页底混入功能主色（对齐喂养 sheet 玻璃 tint）
    final bgStart = AppColor.pageBg(context);
    final bgEnd = Color.lerp(bgStart, accent, 0.28) ?? scheme.surface;

    ref.listen(growthTrajectoryStateProvider, (prev, next) {
      // 离开提问态或新题：取消语音采集
      final leftAsking = prev?.phase == GrowthTrajectoryPhase.asking &&
          next.phase != GrowthTrajectoryPhase.asking;
      final qChanged = prev?.question?.id != next.question?.id;
      if (leftAsking || qChanged) {
        unawaited(_cancelVoiceSession());
      }
      if (prev?.question?.id == next.question?.id) return;
      if (!_choiceManualMode && _freeTextController.text.isEmpty) return;
      setState(_collapseChoiceManual);
    });

    ref.listen(featureCatalogStateProvider, (prev, next) {
      final was = isFeatureEffectivelyUnlocked(
        item: prev?.byId(kFeatureIdGrowthTrajectoryPredict),
        isVip: isVip,
      );
      final now = isFeatureEffectivelyUnlocked(
        item: next.byId(kFeatureIdGrowthTrajectoryPredict),
        isVip: isVip,
      );
      if (!was && now) {
        unawaited(
          ref
              .read(growthTrajectoryStateProvider.notifier)
              .ensureLatest(force: true),
        );
      }
    });
    ref.listen(vipStatusProvider, (prev, next) {
      final wasVip = prev?.valueOrNull?.isVip == true;
      final nowVip = next.valueOrNull?.isVip == true;
      if (!wasVip && nowVip) {
        unawaited(
          ref
              .read(growthTrajectoryStateProvider.notifier)
              .ensureLatest(force: true),
        );
      }
    });

    // 主 CTA 在正文下。思考流与加载历史不放按钮；提问中只放「重新预测」。
    Widget? bottomCta;
    final hideCta = gt.phase == GrowthTrajectoryPhase.streaming ||
        gt.phase == GrowthTrajectoryPhase.loadingLatest;
    if (gt.phase == GrowthTrajectoryPhase.asking && canUse) {
      // 选项在 body 里；此按钮在 ListView 正文下方，不进选项组。
      bottomCta = _GrowthBodyCta(
        label: '重新预测',
        accent: accent,
        usageCopy: gt.usageCopy,
        onTap: () => _onPredict(restart: true),
      );
    } else if (!hideCta) {
      if (!canUse) {
        bottomCta = _GrowthBodyCta(
          label: '轨迹预测',
          accent: accent,
          onTap: () => openGrowthTrajectoryInviteUnlockDialog(
            context: context,
            ref: ref,
            feature: feature,
          ),
        );
      } else if (gt.hasResult) {
        bottomCta = _GrowthBodyCta(
          label: '重新预测',
          accent: accent,
          usageCopy: gt.usageCopy,
          onTap: () => _onPredict(restart: true),
        );
      } else {
        bottomCta = _GrowthBodyCta(
          label: '轨迹预测',
          accent: accent,
          usageCopy: gt.usageCopy,
          onTap: () => _onPredict(restart: false),
        );
      }
    }

    // 页内文案跟成长功能色（浅底加深）。
    final deep = _gtDeepenAccent(accent);
    final muted = deep.withValues(alpha: 0.85);
    final hint = accent.withValues(alpha: 0.55);

    Widget body;
    if (!canUse) {
      body = _gtMuted(
        context,
        '点击「轨迹预测」，结合宝宝近况定制未来 7 天成长提示',
        muted,
      );
    } else if (gt.phase == GrowthTrajectoryPhase.loadingLatest) {
      body = _gtMuted(context, '正在加载历史轨迹…', muted);
    } else if (gt.showThinking || gt.phase == GrowthTrajectoryPhase.streaming) {
      // 仅流式思考展示等待说明；提问阶段不走此分支。
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisWaitCallout(accent: accent),
          const SizedBox(height: 12),
          AiThinkingPane(
            text: gt.thinking.isEmpty ? '正在思考…' : gt.thinking,
            accentColor: deep,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: deep.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    } else if (gt.phase == GrowthTrajectoryPhase.asking && gt.question != null) {
      final q = gt.question!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.prompt,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: deep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (q.isChoice && !_choiceManualMode) ...[
            // 纵向全宽，便于长文案
            for (final c in q.twoChoices) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: _choiceButtonShape,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => unawaited(_onChoice(c)),
                  child: Text(c, textAlign: TextAlign.center),
                ),
              ),
              if (c != q.twoChoices.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: hint,
                ),
                onPressed: () => setState(() => _choiceManualMode = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_alt_outlined, size: 14, color: hint),
                    const SizedBox(width: 4),
                    Text(
                      '手动输入',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: hint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (q.isChoice && _choiceManualMode) ...[
            _buildAskTextField(
              accent: accent,
              scheme: scheme,
              hintText: '请输入补充说明',
            ),
            const SizedBox(height: 8),
            // 手动输入：按住说话填框（共用全局 ASR）
            _buildHoldToTalkBar(accent: accent, scheme: scheme),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    unawaited(_cancelVoiceSession());
                    setState(_collapseChoiceManual);
                  },
                  child: const Text('收起'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => unawaited(_onSubmitFreeText()),
                  child: const Text('提交'),
                ),
              ],
            ),
          ] else ...[
            _buildAskTextField(
              accent: accent,
              scheme: scheme,
              hintText: '请输入补充说明',
            ),
            const SizedBox(height: 8),
            // free_text：按住说话填框（松手不自动提交）
            _buildHoldToTalkBar(accent: accent, scheme: scheme),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => unawaited(_onSubmitFreeText()),
                child: const Text('提交'),
              ),
            ),
          ],
        ],
      );
    } else if (gt.hasResult) {
      body = ClinicAnswerBody(
        text: gt.resultMarkdown,
        streaming: false,
        scrollable: false,
        selectable: true,
      );
    } else {
      body = _gtMuted(
        context,
        '点击「轨迹预测」，结合宝宝近况定制未来 7 天成长提示',
        muted,
      );
    }

    return ClientUsageShowOnce(
      event: ClientUsageEvents.growthShow,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onShell,
        title: Row(
          children: [
            FeatureLogo(
              logoUrl: feature?.logo ?? '',
              size: 26,
              accent: accent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '成长轨迹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _GrowthBlurb(accent: accent),
              const SizedBox(height: 12),
              body,
              if (bottomCta != null) ...[
                const SizedBox(height: 28),
                Center(child: bottomCta),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _gtMuted(BuildContext context, String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, height: 1.35, color: color),
    );
  }
}

/// 浅底正文加深（对齐 Hub / 喂养工作台）。
Color _gtDeepenAccent(Color accent) =>
    Color.lerp(accent, const Color(0xFF000000), 0.18)!;

class _GrowthBlurb extends StatelessWidget {
  const _GrowthBlurb({required this.accent});

  final Color accent;

  static const _copy =
      '通过宝宝近况，结合月龄与近期喂养，预测接下来 7 天可能的成长变化与注意事项。';

  @override
  Widget build(BuildContext context) {
    final deep = _gtDeepenAccent(accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.fieldFill(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          _copy,
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: deep,
          ),
        ),
      ),
    );
  }
}

/// 正文下方居中：预测按钮 + 可选用量小字。
class _GrowthBodyCta extends StatelessWidget {
  const _GrowthBodyCta({
    required this.label,
    required this.onTap,
    required this.accent,
    this.usageCopy,
  });

  final String label;
  final Future<void> Function() onTap;
  final Color accent;
  final String? usageCopy;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => unawaited(onTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ),
    );
    final usage = usageCopy?.trim();
    if (usage == null || usage.isEmpty) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          usage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: accent.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
