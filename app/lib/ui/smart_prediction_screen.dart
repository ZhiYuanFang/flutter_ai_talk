import 'dart:async';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pangbao_app/ui/widgets/app_glass_overlay.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/prediction_layout_store.dart';
import '../data/active_timing_stop.dart';
import '../data/event_branding.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import '../data/prediction_care_alert.dart';
import '../data/prediction_demo_skeleton.dart';
import '../data/prediction_recall_seed.dart';
import '../data/event_next_predictor.dart';
import '../data/smart_prediction_rows.dart';
import '../home_widget/format_widget_relative_time.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/forecast_toggle_provider.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../providers/prediction_gate_provider.dart';
import '../providers/prediction_landscape_column_provider.dart';
import '../providers/prediction_layout_provider.dart';
import '../providers/prediction_range_history_provider.dart';
import '../providers/prediction_recall_provider.dart';
import '../providers/session_provider.dart';
import '../providers/baby_display_provider.dart';
import '../providers/landscape_voice_provider.dart';
import '../providers/smart_prediction_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_theme_schedule.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import 'event_add_actions.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_modal_glass_panel.dart';
import 'event_logo.dart';
import 'prediction_recall_interval_picker.dart';
import 'prediction_recall_onboarding_panel.dart';
import '../config/prediction_landscape_column_store.dart';
import 'prediction_landscape_card_metrics.dart';
import 'prediction_voice_edge_dock.dart';
import 'theme_palette_sheet.dart';
import 'widgets/app_toast.dart';
import 'widgets/baby_avatar.dart';
import 'widgets/app_empty_state_gallery.dart';
import 'widgets/feeding_eligibility_progress_text.dart';
import 'widgets/prediction_widget_showcase_fab.dart';

/// 投屏入口：锁定横屏（与 [_exitLandscapeToPortrait] 对称）。
Future<void> _lockPredictionLandscapeCast() async {
  if (kIsWeb) return;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// 右栏退出：先切竖屏，再恢复全方向旋转。
Future<void> _exitLandscapeToPortrait() async {
  if (kIsWeb) return;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
}

/// 预测开关闸：关始终放行；开时 VIP 放行，否则已开启数须 < 永久 allowedCount。
/// 满额弹框确认后进入开通中心。返回是否已执行开启。
Future<bool> _requestForecastToggle({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
  required bool enable,
  required int enabledCount,
  required bool currentlyEnabled,
  required int allowedCount,
  required bool isVip,
}) async {
  if (!enable) {
    await ref.read(forecastDisabledIdsProvider.notifier).setEnabled(eventId, false);
    return true;
  }
  if (currentlyEnabled) return true;
  // allowedCount < 0：历史全开哨兵，视为不限名额。
  final capped = !isVip && allowedCount >= 0 && enabledCount >= allowedCount;
  if (capped) {
    final go = await showGlassConfirmDialog(
      context,
      title: '预测槽位已满',
      message: allowedCount <= 0
          ? '当前还没有可开启的预测槽位。'
          : '已开启 $enabledCount 个预测事件。输入邀请码开启更多预测槽位。',
      confirmLabel: '去开通',
    );
    if (go == true && context.mounted) {
      context.push('/features/unlock');
    }
    return false;
  }
  await ref.read(forecastDisabledIdsProvider.notifier).setEnabled(eventId, true);
  return true;
}

/// Auth 冷态滑动引导：点箭头教滑动，不跳页、不开门闸。
Future<void> _showSwipeGuideTeachDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showGlassDialog<void>(
    context: context,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('知道了'),
          ),
        ],
      );
    },
  );
}

/// 预测页横屏：沉浸藏状态栏 + 常亮；离开/竖屏释放。
class _PredictionLandscapeImmersiveHost extends StatefulWidget {
  const _PredictionLandscapeImmersiveHost({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_PredictionLandscapeImmersiveHost> createState() =>
      _PredictionLandscapeImmersiveHostState();
}

class _PredictionLandscapeImmersiveHostState
    extends State<_PredictionLandscapeImmersiveHost>
    with WidgetsBindingObserver {
  var _held = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_sync(widget.active));
  }

  @override
  void didUpdateWidget(covariant _PredictionLandscapeImmersiveHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      unawaited(_sync(widget.active));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从媒体全屏等回流后，若仍应沉浸则重同步。
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync(widget.active));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_release());
    super.dispose();
  }

  Future<void> _sync(bool active) async {
    if (kIsWeb) return;
    if (active) {
      _held = true;
      try {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        await WakelockPlus.enable();
      } catch (_) {
        // 平台失败不阻断 UI；下次 sync / resume 再试。
      }
      return;
    }
    await _release();
  }

  Future<void> _release() async {
    if (!_held) return;
    _held = false;
    if (kIsWeb) return;
    try {
      await WakelockPlus.disable();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 智能预测页：留意跑马灯 + 三小时时间线 + 列表/瀑布流卡片。
class SmartPredictionScreen extends ConsumerWidget {
  const SmartPredictionScreen({super.key});

  /// 未超时、推演开、可预测中 nextAt 最早者（并列取先出现）。
  static String? soonestHeartbeatEventId(
    List<SmartPredictionRow> rows,
    DateTime now,
  ) {
    String? bestId;
    DateTime? bestAt;
    for (final r in rows) {
      if (!r.forecastEnabled) continue;
      final p = r.prediction;
      if (p == null || p.isOverdue(now)) continue;
      if (bestAt == null || p.nextAt.isBefore(bestAt)) {
        bestAt = p.nextAt;
        bestId = r.eventId;
      }
    }
    return bestId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realRows = ref.watch(smartPredictionRowsProvider);
    final ensureAsync = ref.watch(predictionRangeEnsureProvider);
    final rangeState = ref.watch(predictionRangeHistoryProvider);
    final catalog = ref.watch(eventCatalogProvider).items;
    final layout = ref.watch(predictionCardsLayoutProvider).asData?.value ??
        PredictionCardsLayout.grid;
    final now =
        ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
    final chartsLoading =
        ensureAsync.isLoading || ensureAsync.isRefreshing || rangeState.loading;
    // 仅「未 ready 且仍在拉」算 pending；失败/跳过后不得永久「正在加载中」
    final rangePending =
        !rangeState.ready && (rangeState.loading || chartsLoading);
    final babyDisplay = ref.watch(babyDisplayProvider);
    // 身份顶栏：经展示快照 Provider（L2）。
    final nickname = babyDisplay.nickname;
    final ageText = babyDisplay.ageText;
    final loggedIn = ref.watch(sessionProvider).isLoggedIn;
    final deviceNo =
        ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
    final bound = loggedIn && deviceNo.isNotEmpty;
    final emptyHistoryEligible =
        ref.watch(predictionRecallEmptyHistoryEligibleProvider);
    // 冷态：未登录 / 未绑定 / 已绑定且 range 空就绪 → 骨架
    // final useDemoSkeleton = !loggedIn || !bound || emptyHistoryEligible;
    final useDemoSkeleton = !loggedIn || !bound;
    final mountNonce = ref.watch(predictionDemoMountNonceProvider);
    final mountNow = ref.watch(predictionDemoMountNowProvider);
    final rows = useDemoSkeleton
        ? buildPredictionDemoSkeletonRows(
            catalog: catalog,
            mountNow: mountNow,
            mountNonce: mountNonce,
          )
        : realRows;
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    // 永久可开启条数；开关闸按「已开启计数」占用，非排序下标。
    final allowedCount =
        ref.watch(featureCatalogStateProvider).predictionAllowedCount;
    final enabledCount = rows.where((r) => r.forecastEnabled).length;
    Future<void> onForecastToggle(String eventId, bool enable) async {
      final currentlyEnabled =
          rows.any((r) => r.eventId == eventId && r.forecastEnabled);
      await _requestForecastToggle(
        context: context,
        ref: ref,
        eventId: eventId,
        enable: enable,
        enabledCount: enabledCount,
        currentlyEnabled: currentlyEnabled,
        allowedCount: allowedCount,
        isVip: isVip,
      );
    }
    final heartbeatId = soonestHeartbeatEventId(rows, now);
    final timelineText = buildNextThreeHoursTimelineText(rows, now);
    final gapRoots = ref.watch(predictionRecallGapRootsProvider);
    final recallDismissed = ref.watch(predictionRecallFinaleDismissedProvider);
    final recallSession = ref.watch(predictionRecallSessionActiveProvider);
    final recallDialogVisible =
        ref.watch(predictionRecallDialogVisibleProvider);
    final loginGateVisible = ref.watch(predictionLoginGateVisibleProvider);
    final bindGateVisible = ref.watch(predictionBindGateVisibleProvider);
    final sessionRoots = ref.watch(predictionRecallSessionRootsProvider);

    // 门闸优先级：未登录 > 未绑定 > 量身定做
    final PredictionGateKind gateKind;
    if (!loggedIn) {
      gateKind = PredictionGateKind.login;
    } else if (!bound) {
      gateKind = PredictionGateKind.bind;
    } else if (emptyHistoryEligible &&
        (recallSession || (gapRoots.isNotEmpty && !recallDismissed))) {
      gateKind = PredictionGateKind.recall;
    } else {
      gateKind = PredictionGateKind.none;
    }

    // 策略 B：有任意真历史或未绑定/未登录则结束量身定做
    if (gateKind != PredictionGateKind.recall && recallSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(predictionRecallSessionActiveProvider.notifier).state = false;
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
        ref.read(predictionRecallSessionRootsProvider.notifier).state =
            const [];
        if (!emptyHistoryEligible || !bound) {
          ref.read(predictionRecallFinaleDismissedProvider.notifier).state =
              true;
        }
      });
    }

    // 已绑定 + 空库就绪 + 有根队列：开启量身定做 Dialog（登录/绑定门闸优先时不启）
    if (gateKind == PredictionGateKind.recall &&
        bound &&
        emptyHistoryEligible &&
        gapRoots.isNotEmpty &&
        !recallSession &&
        !recallDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(predictionRecallSessionRootsProvider.notifier).state =
            List<EventDefinition>.from(gapRoots);
        ref.read(predictionRecallSessionActiveProvider.notifier).state = true;
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
      });
    }
    ref.listen<bool>(predictionRecallEmptyHistoryEligibleProvider,
        (prev, next) {
      if (next && prev == false) {
        ref.read(predictionRecallFinaleDismissedProvider.notifier).state =
            false;
      }
    });

    // 登录成功：停登录引导；绑定引导保持不自动弹（等骨架卡意图）
    ref.listen(sessionProvider, (prev, next) {
      final wasIn = prev?.isLoggedIn == true;
      final nowIn = next.isLoggedIn;
      if (!wasIn && nowIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(predictionLoginGateVisibleProvider.notifier).state = false;
        });
      }
      if (wasIn && !nowIn) {
        // 登出：关闭可见门闸，但不强制下次进页自动弹
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(predictionLoginGateVisibleProvider.notifier).state = false;
          ref.read(predictionBindGateVisibleProvider.notifier).state = false;
        });
      }
    });

    // 绑定成功：停绑定引导；解绑后不自动弹（等骨架卡意图）
    ref.listen(deviceNoNotifierProvider, (prev, next) {
      final dn = next.asData?.value?.trim() ?? '';
      final prevDn = prev?.asData?.value?.trim() ?? '';
      if (prevDn.isEmpty && dn.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(predictionBindGateVisibleProvider.notifier).state = false;
        });
      }
      if (prevDn.isNotEmpty &&
          dn.isEmpty &&
          ref.read(sessionProvider).isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(predictionBindGateVisibleProvider.notifier).state = false;
        });
      }
    });

    final recallSessionLive = gateKind == PredictionGateKind.recall &&
        bound &&
        emptyHistoryEligible &&
        recallSession &&
        !recallDismissed;

    final showLoginGate =
        gateKind == PredictionGateKind.login && loginGateVisible;
    final showBindGate = gateKind == PredictionGateKind.bind && bindGateVisible;

    void openSettings() {
      if (!ref.read(sessionProvider).isLoggedIn) {
        context.push('/login');
        return;
      }
      context.push('/settings');
    }

    // 关闭门闸
    void softDismissActiveGate() {
      if (gateKind == PredictionGateKind.login) {
        ref.read(predictionLoginGateVisibleProvider.notifier).state = false;
      } else if (gateKind == PredictionGateKind.bind) {
        ref.read(predictionBindGateVisibleProvider.notifier).state = false;
      } else if (gateKind == PredictionGateKind.recall) {
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
      }
    }

    /// 骨架卡等意图入口：可打开登录/绑定/量身定做门闸。
    void openGateFromIntent() {
      if (gateKind == PredictionGateKind.login) {
        if (!loginGateVisible) {
          ref.read(predictionLoginGateVisibleProvider.notifier).state = true;
        }
        return;
      }
      if (gateKind == PredictionGateKind.bind) {
        if (!bindGateVisible) {
          ref.read(predictionBindGateVisibleProvider.notifier).state = true;
        }
        return;
      }
      if (recallSessionLive && !recallDialogVisible) {
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = true;
      }
    }

    /// 空白/切布局：仅再弹量身定做，不得打开登录/绑定。
    Future<void> reopenRecallGateIfNeeded() async {
      ref.read(predictionRecallFinaleDismissedProvider.notifier).state = false;
      if (recallSessionLive && !recallDialogVisible) {
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = true;
        return;
      }
      if (!bound || !emptyHistoryEligible || recallSession) return;

      var roots = gapRoots;
      if (roots.isEmpty) {
        // 全跳过后 gapRoots 为空：重开目录根推演再拉起会话。
        final toggle = ref.read(forecastDisabledIdsProvider.notifier);
        for (final root in rootEvents(catalog)) {
          if (root.id.isEmpty) continue;
          await toggle.setEnabled(root.id, true);
        }
        roots = ref.read(predictionRecallGapRootsProvider);
      }
      if (roots.isEmpty) return;

      ref.read(predictionRecallSessionRootsProvider.notifier).state =
          List<EventDefinition>.from(roots);
      ref.read(predictionRecallSessionActiveProvider.notifier).state = true;
      ref.read(predictionRecallDialogVisibleProvider.notifier).state = true;
    }

    void finishRecallOnboarding({required bool permanentDismiss}) {
      if (permanentDismiss) {
        ref.read(predictionRecallFinaleDismissedProvider.notifier).state = true;
      }
      ref.read(predictionRecallSessionActiveProvider.notifier).state = false;
      ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
      ref.read(predictionRecallSessionRootsProvider.notifier).state = const [];
    }

    // Auth 冷态（未登录/未绑定）：滑动引导大卡，不展示留意/3小时。
    final authGuestChrome = !loggedIn || !bound;

    final Widget? careOrGuide;
    if (authGuestChrome) {
      careOrGuide = const _PredictionSwipeGuideCard();
    } else if (useDemoSkeleton) {
      // 冷态：不展示健康假卡
      careOrGuide = null;
    } else {
      final careElig = ref.watch(careAlertEligibilityStateProvider);
      final careItems = ref.watch(predictionCareAlertProvider);
      final careState = ref.watch(predictionCareAlertStateProvider);
      // 未合格 / 资格失败：仍展示卡片进度；合格且有数据：跑马灯。
      if (!careElig.isQualified) {
        if (careElig.loading) {
          careOrGuide = _CareAlertPanel(
            items: const [],
            progressSubtitle: '正在校验喂养记录…',
            onTapItem: (_) {},
          );
        } else if (careElig.failed) {
          careOrGuide = _CareAlertPanel(
            items: const [],
            progressSubtitle: '资格校验失败，请稍后重试',
            onTapItem: (_) {},
          );
        } else if (careElig.data != null) {
          careOrGuide = _CareAlertPanel(
            items: const [],
            progressSubtitleWidget: FeedingEligibilityProgressText(
              eligibility: careElig.data!,
              kind: FeedingEligibilityProgressKind.careAlert,
              textAlign: TextAlign.start,
              numberScale: 1.65,
            ),
            onTapItem: (_) {},
          );
        } else {
          careOrGuide = _CareAlertPanel(
            items: const [],
            progressSubtitle: '需累计有效喂养日以激活值得留意',
            onTapItem: (_) {},
          );
        }
      } else {
        final showCare = careState.ready &&
            !careState.failed &&
            !careState.loading &&
            careItems.isNotEmpty;
        careOrGuide = showCare
            ? _CareAlertPanel(
                items: careItems,
                onTapItem: (item) {
                  context.push('/prediction/alert', extra: item);
                },
              )
            : (careState.loading
                ? _CareAlertPanel(
                    items: const [],
                    progressSubtitle: '正在生成值得留意…',
                    onTapItem: (_) {},
                  )
                : null);
      }
    }

    // 网格计时中 chrome：从喂养历史匹配进行中记录
    final historyItems = ref.watch(homeHistoryProvider).items;
    // 落库飞入：按 root 挂当前展示 logo 锚点
    final logoAnchors = ref.watch(predictionLogoAnchorRegistryProvider);
    logoAnchors.retainOnly(rows.map((r) => r.eventId));

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // 横屏投屏护眼：派生暗壳 Theme（保留 seed tint）；已暗透传；不写 baseline。
    final landscapeTheme = isLandscape
        ? landscapeTvSafeThemeOf(
            current: Theme.of(context),
            sex: ref.watch(babySexProvider),
            effectiveSeed: ref.watch(effectiveThemeProvider).seed,
            effectivePreset: ref.watch(effectiveThemeProvider).preset,
          )
        : null;
    final pageTheme = landscapeTheme ?? Theme.of(context);
    final pageTokens = pageTheme.extension<AppVisualTokens>();
    final shell = pageTokens?.shellColor ?? pageTheme.colorScheme.surface;
    final onShell = pageTokens?.onShell ?? pageTheme.colorScheme.onSurface;
    // 横屏强制瀑布；竖屏尊重本地偏好。
    final useGridLayout = isLandscape || layout == PredictionCardsLayout.grid;
    // 竖屏 2；横屏读持久化列数（默认手机 3 / 平板 5，可调 1–7）。
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isTabletLandscape = isLandscape && shortestSide >= 600;
    final storedLandscapeColumns =
        ref.watch(predictionLandscapeColumnProvider).asData?.value;
    final landscapeColumnCount = isLandscape
        ? effectiveLandscapeColumnCount(
            stored: storedLandscapeColumns,
            isTabletLandscape: isTabletLandscape,
          )
        : 2;
    final waterfallColumns = isLandscape ? landscapeColumnCount : 2;
    // 仅手机横屏后列侧 logo；平板横屏不启用。
    final phoneLandscape = isLandscape && !isTabletLandscape;
    // KeepAlive 下须结合当前 pager 页，滑离预测即释放沉浸/常亮。
    final predictionPageVisible =
        ref.watch(homePagerIndexProvider) == HomePagerPage.prediction;
    final immersiveActive = !kIsWeb && isLandscape && predictionPageVisible;

    // 竖屏秀小组件入口：须已绑定；列表底留白避免遮挡
    final showWidgetShowcaseFab = bound &&
        !isLandscape &&
        PredictionWidgetShowcaseFab.isPlatformSupported;
    final cardsBottomPad = showWidgetShowcaseFab ? 96.0 : 24.0;

    // 竖屏语音暂停时仅横屏 watch，避免竖屏无入口仍驱动会话状态
    final landscapeVoice =
        (isLandscape || kPredictionPortraitVoiceEnabled)
            ? ref.watch(landscapeVoiceControllerProvider)
            : null;

    Widget buildCardsBody() {
      if (rows.isEmpty) {
        return Center(
          child: useDemoSkeleton || !rangePending
              ? AppEmptyStateGallery(
                  fallbackIcon: Icons.online_prediction, // 注意：需要替换为实际的图标名称
                  title: '智能预测 · 伴随宝宝成长',
                  subtitle: '跟随系统引导，体验基础预测。\n随着后续真实的喂养记录累计，预测能力将自动成长。',
                  // 如果是横屏则不显示actionLabel
                  actionLabel: '回忆宝宝习惯',
                  onAction: () => unawaited(reopenRecallGateIfNeeded()),
                  animationPath: '',
                )
              : Text(
                  '正在加载中',
                  style: TextStyle(
                    color: onShell.withValues(alpha: 0.55),
                  ),
                ),
        );
      }
      if (useGridLayout) {
        Widget buildGrid({PredictionLandscapeCardMetrics? metrics}) {
          return _WaterfallCards(
            padding: EdgeInsets.fromLTRB(
              isLandscape ? 8 : 16,
              isLandscape ? 12 : 0,
              isLandscape ? 8 : 16,
              cardsBottomPad,
            ),
            rows: rows,
            columnCount: waterfallColumns,
            columnGap: metrics?.columnGap ?? 12,
            rowGap: metrics?.rowGap ?? 12,
            itemBuilder: (row, columnIndex, rowIndexInColumn) {
              final activeTiming = useDemoSkeleton
                  ? null
                  : findLatestActiveTimingForRoot(
                      items: historyItems,
                      rootEventId: row.eventId,
                      catalog: catalog,
                    );
              final titleInlineLogo = phoneLandscape && rowIndexInColumn > 0;
              return _PredictionEventCard(
                row: row,
                definition: lookupEventById(catalog, row.eventId),
                logoAnchorKey: logoAnchors.keyFor(row.eventId),
                now: now,
                chartLoading: useDemoSkeleton ? false : chartsLoading,
                compact: true,
                titleInlineLogo: titleInlineLogo,
                heartbeat: row.eventId == heartbeatId,
                chartPoints: const [],
                pastDaysBeforeToday: 2,
                showYAxis: false,
                relativeText: activeTiming != null
                    ? null
                    : _relativeFor(row, now, grid: true),
                activeTiming: activeTiming,
                landscapeMetrics: metrics,
                onToggle: useDemoSkeleton
                    ? null
                    : (v) {
                        unawaited(onForecastToggle(row.eventId, v));
                      },
                onCardTap: activeTiming != null
                    ? null
                    : () {
                        if (useDemoSkeleton) {
                          if (!loggedIn || !bound) {
                            openGateFromIntent();
                            return;
                          }
                          showAppToast('先完成量身定做，或去喂养页记一笔吧');
                          return;
                        }
                        final def = lookupEventById(catalog, row.eventId);
                        if (def == null) return;
                        unawaited(
                          handleEventGridTap(
                            context: context,
                            ref: ref,
                            event: def,
                            confirmDirectLeafBeforeAdd: true,
                          ),
                        );
                      },
              );
            },
          );
        }

        if (isLandscape) {
          return LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPad = 16.0;
              final metrics = PredictionLandscapeCardMetrics.forGrid(
                gridWidth: (constraints.maxWidth - horizontalPad)
                    .clamp(1.0, double.infinity),
                columnCount: waterfallColumns,
                isTabletLandscape: isTabletLandscape,
              );
              return buildGrid(metrics: metrics);
            },
          );
        }
        return buildGrid();
      }
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 0, 16, cardsBottomPad),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final row = rows[i];
          return _PredictionEventCard(
            row: row,
            definition: lookupEventById(catalog, row.eventId),
            logoAnchorKey: logoAnchors.keyFor(row.eventId),
            now: now,
            chartLoading: useDemoSkeleton ? false : chartsLoading,
            compact: false,
            heartbeat: false,
            chartPoints: useDemoSkeleton ? const [] : row.chartPoints,
            pastDaysBeforeToday: 6,
            showYAxis: !useDemoSkeleton,
            relativeText: _relativeFor(row, now, grid: false),
            onToggle: useDemoSkeleton
                ? null
                : (v) {
                    unawaited(onForecastToggle(row.eventId, v));
                  },
          );
        },
      );
    }

    // 登录 / 绑定 / 量身定做门闸（横竖屏共用）。
    final List<Widget> gateOverlays = [
      if (showLoginGate || showBindGate)
        _PredictionSoftGateOverlay(
          onDismiss: softDismissActiveGate,
          child: _PredictionAuthGateCard(
            title: showLoginGate ? '尚未登录' : '嗨，我是胖宝！',
            subtitle: showLoginGate
                ? '登录后即可使用智能预测，记录与陪伴宝宝日常'
                : '我想更好地陪伴宝宝成长，先绑定宝宝信息吧',
            actionLabel: showLoginGate ? '去登录' : '立即绑定宝宝',
            onAction: () {
              if (showLoginGate) {
                context.push('/login');
              } else {
                context.push('/settings/bind-baby');
              }
            },
          ),
        ),
      if (recallSessionLive)
        Visibility(
          visible: recallDialogVisible,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: false,
          child: _PredictionSoftGateOverlay(
            onDismiss: softDismissActiveGate,
            maxHeightFactor: isLandscape ? 0.90 : 0.72,
            fillMaxHeight: true,
            child: PredictionRecallOnboardingPanel(
              gapRoots: sessionRoots.isNotEmpty ? sessionRoots : gapRoots,
              catalog: catalog,
              onFinished: finishRecallOnboarding,
            ),
          ),
        ),
    ];

    final Widget pageBody;

    if (isLandscape) {
      // 横屏：左身份 | 中瀑布 | 右密度轨；语音悬浮相对整屏左下（非网格左下）。
      final mqPad = MediaQuery.paddingOf(context);
      final voiceBottom = 10.0 + mqPad.bottom;
      const densityRailWidth = 36.0;
      const densityRailTrailingPad = 6.0;
      pageBody = Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PredictionLandscapeIdentityRail(
                nickname: nickname,
                ageText: babyDisplay.showAge ? ageText : '',
                babyId: babyDisplay.babyId,
                sex: babyDisplay.sex,
                onAvatarTap: openSettings,
                color: onShell,
              ),
              Expanded(
                child: Stack(
                  children: [
                    // 横屏语音生命周期（零尺寸，避免每帧重复 activate）
                    _LandscapeVoiceLifecycleBinder(
                      landscape: isLandscape,
                      predictionVisible: predictionPageVisible,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 冷态骨架：与竖屏同步，列表上方居中「虚拟事件举例」
                        if (useDemoSkeleton)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                            child: _PredictionVirtualEventsBanner(
                              onShell: onShell,
                            ),
                          ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            // onTap: reopenRecallGateIfNeeded,
                            child: buildCardsBody(),
                          ),
                        ),
                      ],
                    ),
                    ...gateOverlays.map(
                      (w) => Positioned.fill(child: w),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(0, 12, densityRailTrailingPad, 8),
                child: SizedBox(
                  width: densityRailWidth,
                  child: _LandscapeColumnDensitySideRail(
                    columnCount: landscapeColumnCount,
                    onColumnCountChanged: (n) => ref
                        .read(predictionLandscapeColumnProvider.notifier)
                        .setCount(n),
                    onExitLandscape: () =>
                        unawaited(_exitLandscapeToPortrait()),
                    color: onShell,
                  ),
                ),
              ),
            ],
          ),
          if (landscapeVoice != null) ...[
            // 整屏左下：监听 chip（压在身份栏区域之上）
            Positioned(
              left: 8 + mqPad.left,
              bottom: voiceBottom,
              child: _LandscapeVoiceListenChip(
                caption: landscapeVoice.statusCaption,
                chatConnected: landscapeVoice.chatConnected,
                chatListening: landscapeVoice.chatListening,
                onTap: () => ref
                    .read(landscapeVoiceControllerProvider.notifier)
                    .onListenChipTap(context),
              ),
            ),
            // 整屏底部偏上字幕 toast（随内容宽度，居中）
            if (landscapeVoice.subtitle.trim().isNotEmpty)
              Positioned(
                left: 56 + mqPad.left,
                right: 16 +
                    densityRailWidth +
                    densityRailTrailingPad +
                    mqPad.right,
                bottom: MediaQuery.sizeOf(context).height * 0.18,
                child: IgnorePointer(
                  child: _LandscapeVoiceSubtitleToast(
                    text: landscapeVoice.subtitle,
                    isThinking: landscapeVoice.subtitleKind ==
                        LandscapeVoiceSubtitleKind.thinking,
                  ),
                ),
              ),
          ],
        ],
      );
    } else {
      // 竖屏：原有 Column 改为 Stack，叠加语音组件
      final mqPad = MediaQuery.paddingOf(context);
      final voiceBottom = 86.0 + mqPad.bottom; // 避开底部导航栏

      pageBody = Stack(
        children: [
          // 原有竖屏内容
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                        child: Row(
                          children: [
                            BabyAvatar(
                              babyId: babyDisplay.babyId,
                              sex: babyDisplay.sex,
                              radius: 20,
                              onTap: openSettings,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: onShell,
                                        ),
                                  ),
                                  // 未登录/未绑定不展示月龄行。
                                  if (babyDisplay.showAge &&
                                      ageText.trim().isNotEmpty)
                                    Text(
                                      ageText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                onShell.withValues(alpha: 0.65),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // icon button 点击弹出对话框，是否进入投屏模式（下方小字：请自行操作手机投屏到电视上）
                    IconButton(
                      onPressed: () async {
                        final go = await showGlassConfirmDialog(
                              context,
                              title: '进入投屏模式',
                              message:
                                  '请将手机画面投屏到电视后继续。\n进入横屏后，可点击右侧栏顶部的返回竖屏图标退出，并恢复屏幕旋转。',
                              confirmLabel: '已投屏',
                            ) ??
                            false;
                        if (go && context.mounted) {
                          unawaited(_lockPredictionLandscapeCast());
                        }
                      },
                      icon: const Icon(Icons.cast),
                    ),

                    IconButton(
                      tooltip: layout == PredictionCardsLayout.grid
                          ? '切换为纵向列表'
                          : '切换为瀑布流',
                      onPressed: () {
                        // reopenRecallGateIfNeeded();
                        ref
                            .read(predictionCardsLayoutProvider.notifier)
                            .toggle();
                      },
                      icon: Icon(
                        layout == PredictionCardsLayout.grid
                            ? Icons.view_agenda_outlined
                            : Icons.dashboard_customize_outlined,
                        color: onShell,
                      ),
                    ),
                    const ThemePaletteIconButton(),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // 空白 tap 仅再弹量身定做；登录/绑定须骨架卡意图
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      // onTap: reopenRecallGateIfNeeded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (careOrGuide != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: careOrGuide,
                            ),
                          // Auth 冷态不展示接下来3小时；已绑定冷态/热态照旧。
                          if (!authGuestChrome && timelineText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _NextThreeHoursTimeline(
                                body: timelineText,
                                onOpenFeeding: () {
                                  ref
                                      .read(homePagerRequestProvider.notifier)
                                      .requestPage(HomePagerPage.feeding);
                                },
                              ),
                            ),
                          // 与滑动引导大卡并存：凡骨架均在事件列表上方提示虚拟举例
                          if (useDemoSkeleton)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _PredictionVirtualEventsBanner(
                                onShell: onShell,
                              ),
                            ),
                          Expanded(child: buildCardsBody()),
                        ],
                      ),
                    ),
                    ...gateOverlays.map(
                      (w) => Positioned.fill(child: w),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 竖屏语音：模型未就绪时 flag 关闭，完全无入口 / 不 activate
          if (kPredictionPortraitVoiceEnabled && landscapeVoice != null) ...[
            // 竖屏语音生命周期绑定（零尺寸）
            _LandscapeVoiceLifecycleBinder(
              landscape: false,
              predictionVisible: predictionPageVisible,
            ),
            // 竖屏语音贴边球（EdgeDockShell）
            Positioned.fill(
              child: PredictionVoiceEdgeDock(
                statusCaption: landscapeVoice.statusCaption,
                chatConnected: landscapeVoice.chatConnected,
                chatListening: landscapeVoice.chatListening,
                bottomReserve: voiceBottom,
                onPointerOccupied: (occupied) {
                  ref.read(homePagerScrollBlockedProvider.notifier).state =
                      occupied;
                },
                onListenTap: () => ref
                    .read(landscapeVoiceControllerProvider.notifier)
                    .onListenChipTap(context),
              ),
            ),
            // 竖屏语音字幕 toast（底中独立，不随球）
            if (landscapeVoice.subtitle.trim().isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: voiceBottom + 24,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _LandscapeVoiceSubtitleToast(
                      text: landscapeVoice.subtitle,
                      isThinking: landscapeVoice.subtitleKind ==
                          LandscapeVoiceSubtitleKind.thinking,
                    ),
                  ),
                ),
              ),
          ],
          // 竖屏桌面小组件入口（仅移动端竖屏）
          if (showWidgetShowcaseFab)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Center(child: PredictionWidgetShowcaseFab()),
            ),
        ],
      );
    }
    Widget host = _PredictionLandscapeImmersiveHost(
      active: immersiveActive,
      child: Material(
        color: shell,
        // 横屏取消顶/底 SafeArea，最大化看板；左右仍避刘海。
        child: SafeArea(
          top: !isLandscape,
          bottom: !isLandscape,
          child: pageBody,
        ),
      ),
    );
    // 横屏子树挂暗壳 Theme，使 AppColor / chip / 弹幕与壳一体；竖屏不覆盖。
    if (landscapeTheme != null) {
      // host = Theme(data: landscapeTheme, child: host);
    }
    // 供全局 showAppToast（SnackBar）挂载；本页无传统 AppBar。
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: host,
    );
  }

  static String? _relativeFor(
    SmartPredictionRow row,
    DateTime now, {
    required bool grid,
  }) {
    if (!row.forecastEnabled) return null;
    final pred = row.prediction;
    if (pred == null) return null;
    final overdue = pred.isOverdue(now);
    if (grid) {
      if (!overdue) return null;
      return formatPredictionGridRelative(pred.nextAt, now, overdue: true);
    }
    return formatWidgetPredictSubtitle(pred.nextAt, now, overdue: overdue);
  }
}

/// 绑定横屏语音 activate/deactivate，仅在条件变化时触发。
class _LandscapeVoiceLifecycleBinder extends ConsumerStatefulWidget {
  const _LandscapeVoiceLifecycleBinder({
    required this.landscape,
    required this.predictionVisible,
  });

  final bool landscape;
  final bool predictionVisible;

  @override
  ConsumerState<_LandscapeVoiceLifecycleBinder> createState() =>
      _LandscapeVoiceLifecycleBinderState();
}

class _LandscapeVoiceLifecycleBinderState
    extends ConsumerState<_LandscapeVoiceLifecycleBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant _LandscapeVoiceLifecycleBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landscape != widget.landscape ||
        oldWidget.predictionVisible != widget.predictionVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    // 不在此 deactivate：Notifier 可能已 dispose；由 deactivate 在条件变化时处理。
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    syncLandscapeVoiceLifecycle(
      ref,
      context: context,
      landscape: widget.landscape, // 是否横屏,竖屏可用语音时改为true常量
      predictionVisible: widget.predictionVisible,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 横屏左下监听 chip：横向文案超长换行；表面与弹幕同属 panelGlass 族。
class _LandscapeVoiceListenChip extends StatelessWidget {
  const _LandscapeVoiceListenChip({
    required this.caption,
    required this.chatConnected,
    required this.chatListening,
    required this.onTap,
  });

  final String caption;
  final bool chatConnected;
  final bool chatListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 压在 panelGlass 上的文案（与字幕弹幕配对）。
    final onGlass = AppColor.textOnPanelGlass(context);
    final onGlassMuted = AppColor.textOnPanelGlassMuted(context);
    // 已连且本轮上送才高亮话筒；仅已连待唤醒则指示点亮、话筒不高亮。
    final micHot = chatConnected && chatListening;
    // 连接点：未连 error；已连 tertiary（与 mic primary 高亮区分，随主题）。
    final dotColor = chatConnected ? scheme.tertiary : scheme.error;
    const chipRadius = 20.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(chipRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            decoration: BoxDecoration(
              gradient: AppColor.panelGlassGradient(context),
              borderRadius: BorderRadius.circular(chipRadius),
              border: Border.all(
                color: onGlass.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 22,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        micHot ? Icons.mic : Icons.mic_none,
                        size: 22,
                        color: micHot ? scheme.primary : onGlassMuted,
                      ),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColor.panelGlassTop(context)
                                  .withValues(alpha: 0.9),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    caption,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: onGlass.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部偏上字幕条：panelGlass；思考态浅字+慢弱脉冲；首次挂载短淡入。
class _LandscapeVoiceSubtitleToast extends StatefulWidget {
  const _LandscapeVoiceSubtitleToast({
    required this.text,
    required this.isThinking,
  });

  final String text;
  final bool isThinking;

  @override
  State<_LandscapeVoiceSubtitleToast> createState() =>
      _LandscapeVoiceSubtitleToastState();
}

class _LandscapeVoiceSubtitleToastState
    extends State<_LandscapeVoiceSubtitleToast> with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // 仅挂载时淡入；换字不重置。
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    // 思考态慢弱脉冲（约 1.5s 往返）。
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _syncPulse(widget.isThinking);
  }

  @override
  void didUpdateWidget(covariant _LandscapeVoiceSubtitleToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅 kind 切入/离开 thinking 时启停；换字不重启相位。
    if (oldWidget.isThinking != widget.isThinking) {
      _syncPulse(widget.isThinking);
    }
  }

  void _syncPulse(bool thinking) {
    if (thinking) {
      if (!_pulse.isAnimating) {
        unawaited(_pulse.repeat(reverse: true));
      }
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    // 思考用 muted，答案/ASR 满对比。
    final textColor = widget.isThinking
        ? AppColor.textOnPanelGlassMuted(context)
        : onGlass.withValues(alpha: 0.95);
    const toastRadius = 16.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_fade, _pulse]),
      builder: (context, child) {
        // 挂载淡入 × 思考脉冲（非思考时 pulse=1）。
        final pulseOpacity =
            widget.isThinking ? (0.65 + 0.35 * _pulse.value) : 1.0;
        return Opacity(
          opacity: _fade.value * pulseOpacity,
          child: child,
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColor.panelGlassGradient(context),
              borderRadius: BorderRadius.circular(toastRadius),
              border: Border.all(
                color: onGlass.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Auth 冷态滑动引导大卡：无按钮；箭头持续左右位移 + 心跳缩放。
class _PredictionSwipeGuideCard extends StatefulWidget {
  const _PredictionSwipeGuideCard();

  @override
  State<_PredictionSwipeGuideCard> createState() =>
      _PredictionSwipeGuideCardState();
}

class _PredictionSwipeGuideCardState extends State<_PredictionSwipeGuideCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    // 与预测卡心跳节奏接近，持续反向循环。
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _slide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPanel = AppColor.textOnPanelGlass(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.divider(context)),
            gradient: AppColor.panelGlassGradient(context),
          ),
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _slide.value;
              // 左右箭头外扩（反相）：吸睛引导横滑。
              final leftDx = -8.0 * t;
              final rightDx = 8.0 * t;
              return Row(
                children: [
                  // 左箭头：弹框教左滑进广场，不直接跳转。
                  Transform.translate(
                    offset: Offset(leftDx, 0),
                    child: ScaleTransition(
                      scale: _scale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(
                          _showSwipeGuideTeachDialog(
                            context,
                            title: '请向左滑动',
                            message: '左滑可进入广场，看看真实带娃家庭',
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 36,
                          color: onPanel.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '左右滑动，看看别处',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: onPanel,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '左滑进广场 · 右滑去喂养',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: onPanel.withValues(alpha: 0.75),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // 右箭头：弹框教右滑去喂养，不直接跳转。
                  Transform.translate(
                    offset: Offset(rightDx, 0),
                    child: ScaleTransition(
                      scale: _scale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(
                          _showSwipeGuideTeachDialog(
                            context,
                            title: '请向右滑动',
                            message: '右滑可进入喂养，记录宝宝作息',
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 36,
                          color: onPanel.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 软强制引导遮罩：点遮罩关闭；内容居中。
class _PredictionSoftGateOverlay extends StatelessWidget {
  const _PredictionSoftGateOverlay({
    required this.onDismiss,
    required this.child,
    this.maxHeightFactor = 0.55,
    this.fillMaxHeight = false,
  });

  final VoidCallback onDismiss;
  final Widget child;
  final double maxHeightFactor;

  /// 为 true 时子树吃满 maxHeight（量身定做 PageView / 可滚卡需要有界高度）。
  final bool fillMaxHeight;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // 横屏略放宽可用高度，并减小上下留白。
    final factor = landscape
        ? (maxHeightFactor < 0.88 ? 0.88 : maxHeightFactor)
        : maxHeightFactor;
    final vPad = landscape ? 12.0 : 48.0;
    final screenCap = MediaQuery.sizeOf(context).height * factor;

    // 按 overlay 可用高度算，避免用整屏比例把底栏挤出命中盒。
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Color(0x66000000)),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: vPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight < screenCap
                  ? constraints.maxHeight
                  : screenCap;
              return Align(
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxH,
                      maxWidth: 420,
                    ),
                    child: fillMaxHeight
                        ? SizedBox(
                            width: double.infinity,
                            height: maxH,
                            child: child,
                          )
                        : child,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 冷态骨架：事件列表上方居中提示（与滑动引导大卡并存）。
class _PredictionVirtualEventsBanner extends StatelessWidget {
  const _PredictionVirtualEventsBanner({required this.onShell});

  final Color onShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '虚拟事件举例',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: onShell.withValues(alpha: 0.9),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '请右滑补充喂养记录',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onShell.withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}

/// 登录 / 绑定引导卡片。
class _PredictionAuthGateCard extends StatelessWidget {
  const _PredictionAuthGateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    // 登录/绑定引导：统一 modal 原子（暗壳暗浮层 + 配对字色）
    return AppModalGlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColor.textOnModal(context),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.textOnModalMuted(context),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              foregroundColor: AppColor.onPrimary(context),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

/// 「接下来3小时」：折行 + 展开/收起；主区点进喂养页。
class _NextThreeHoursTimeline extends StatefulWidget {
  const _NextThreeHoursTimeline({
    required this.body,
    required this.onOpenFeeding,
  });

  final String body;
  final VoidCallback onOpenFeeding;

  @override
  State<_NextThreeHoursTimeline> createState() =>
      _NextThreeHoursTimelineState();
}

class _NextThreeHoursTimelineState extends State<_NextThreeHoursTimeline> {
  static const int _collapsedMaxLines = 2;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.35,
      color: scheme.onSurface.withValues(alpha: 0.92),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onOpenFeeding,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '接下来3小时',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    // 独立控件：只切折叠，不导航
                    _ExpandToggle(
                      expanded: _expanded,
                      body: widget.body,
                      style: bodyStyle,
                      onToggle: () {
                        setState(() => _expanded = !_expanded);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.body,
                  maxLines: _expanded ? null : _collapsedMaxLines,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 仅在正文超出收起行数时显示展开/收起。
class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({
    required this.expanded,
    required this.body,
    required this.style,
    required this.onToggle,
  });

  final bool expanded;
  final String body;
  final TextStyle style;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // 用屏宽减左右边距估算正文是否超两行
    final maxWidth = MediaQuery.sizeOf(context).width - 16 * 2 - 14 * 2;
    final painter = TextPainter(
      text: TextSpan(text: body, style: style),
      maxLines: _NextThreeHoursTimelineState._collapsedMaxLines,
      textDirection: Directionality.of(context),
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final overflows = painter.didExceedMaxLines;
    if (!overflows && !expanded) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          expanded ? '收起' : '展开',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 值得留意卡片：跑马灯或未激活进度文案。
class _CareAlertPanel extends StatelessWidget {
  const _CareAlertPanel({
    required this.items,
    required this.onTapItem,
    this.progressSubtitle,
    this.progressSubtitleWidget,
  });

  final List<CareAlertEventItem> items;
  final ValueChanged<CareAlertEventItem> onTapItem;
  final String? progressSubtitle;
  final Widget? progressSubtitleWidget;

  @override
  Widget build(BuildContext context) {
    final progress = progressSubtitle?.trim() ?? '';
    final hasRich = progressSubtitleWidget != null;
    if (hasRich || progress.isNotEmpty) {
      final onSurface = Theme.of(context)
          .colorScheme
          .onSurface
          .withValues(alpha: 0.72);
      return _CareAlertShell(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: hasRich
              ? DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: onSurface,
                  ),
                  child: progressSubtitleWidget!,
                )
              : Text(
                  progress,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: onSurface,
                  ),
                ),
        ),
      );
    }
    return _CareAlertShell(
      body: _CareAlertMarquee(
        items: items,
        rowHeight: 44,
        onTapItem: onTapItem,
      ),
    );
  }
}

/// 玻璃拟化外壳（标题 + 正文区）。
class _CareAlertShell extends StatelessWidget {
  const _CareAlertShell({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.divider(context)),
            gradient: AppColor.panelGlassGradient(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                child: Text(
                  '值得留意',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textOnPanelGlass(context),
                  ),
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

/// 严格单行裁切的上下跑马灯。
class _CareAlertMarquee extends StatefulWidget {
  const _CareAlertMarquee({
    required this.items,
    required this.rowHeight,
    required this.onTapItem,
  });

  final List<CareAlertEventItem> items;
  final double rowHeight;
  final ValueChanged<CareAlertEventItem> onTapItem;

  @override
  State<_CareAlertMarquee> createState() => _CareAlertMarqueeState();
}

class _CareAlertMarqueeState extends State<_CareAlertMarquee> {
  static const _autoInterval = Duration(milliseconds: 3500);
  static const _pauseAfterDrag = Duration(seconds: 3);

  late final PageController _controller;
  Timer? _timer;
  Timer? _resumeTimer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAuto();
  }

  @override
  void didUpdateWidget(covariant _CareAlertMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _scheduleAuto();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAuto() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onUserScrollStart() {
    _timer?.cancel();
    _resumeTimer?.cancel();
  }

  void _onUserScrollEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_pauseAfterDrag, _scheduleAuto);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.rowHeight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _onUserScrollStart();
          } else if (n is ScrollEndNotification) {
            _onUserScrollEnd();
          }
          return false;
        },
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _controller,
          itemCount: widget.items.length,
          onPageChanged: (i) => _index = i,
          itemBuilder: (context, i) {
            final item = widget.items[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onTapItem(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.summaryLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: AppColor.textOnPanelGlass(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColor.textOnPanelGlassMuted(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 多列瀑布流：按 index % columnCount 分列，单滚动视口，高度随内容。
class _WaterfallCards extends StatelessWidget {
  const _WaterfallCards({
    required this.padding,
    required this.rows,
    required this.itemBuilder,
    this.columnCount = 2,
    this.columnGap = 12,
    this.rowGap = 12,
  });

  final EdgeInsets padding;
  final List<SmartPredictionRow> rows;

  /// 第二参列索引；第三参列内行索引（0=该列顶卡 / 视觉第一行）。
  final Widget Function(
    SmartPredictionRow row,
    int columnIndex,
    int rowIndexInColumn,
  ) itemBuilder;

  /// 列数（竖屏 2 / 横屏可调）。
  final int columnCount;
  final double columnGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final count = columnCount < 1 ? 1 : columnCount;
    final cols = List.generate(count, (_) => <SmartPredictionRow>[]);
    for (var i = 0; i < rows.length; i++) {
      cols[i % count].add(rows[i]);
    }
    Widget column(List<SmartPredictionRow> col, int columnIndex) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < col.length; i++) ...[
            if (i > 0) SizedBox(height: rowGap),
            itemBuilder(col[i], columnIndex, i),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < count; c++) ...[
            if (c > 0) SizedBox(width: columnGap),
            Expanded(child: column(cols[c], c)),
          ],
        ],
      ),
    );
  }
}

/// 竖排单字列（横屏左栏身份 / 右缘密度提示共用）。
Widget _landscapeVerticalCharColumn(String text, TextStyle? style) {
  final chars = text.runes.map(String.fromCharCode).toList(growable: false);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final ch in chars)
        Text(ch, style: style, textAlign: TextAlign.center),
    ],
  );
}

/// 横屏右缘：返回竖屏 + 竖排「拖动调整大小」+ 拉满至屏底的密度轨。
class _LandscapeColumnDensitySideRail extends StatelessWidget {
  const _LandscapeColumnDensitySideRail({
    required this.columnCount,
    required this.onColumnCountChanged,
    required this.onExitLandscape,
    required this.color,
  });

  final int columnCount;
  final ValueChanged<int> onColumnCountChanged;
  final VoidCallback onExitLandscape;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color.withValues(alpha: 0.55),
          height: 1.15,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: '返回竖屏',
          child: Semantics(
            button: true,
            label: '返回竖屏',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onExitLandscape,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.stay_current_portrait,
                    size: 20,
                    color: color.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _landscapeVerticalCharColumn('拖动调整大小', hintStyle),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _LandscapeColumnDensityTrack(
                trackHeight: constraints.maxHeight.clamp(24.0, double.infinity),
                columnCount: columnCount,
                onColumnCountChanged: onColumnCountChanged,
                color: color,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 纵向密度轨（上=少列大卡，下=多列小卡；真拖，无数字）。
class _LandscapeColumnDensityTrack extends StatefulWidget {
  const _LandscapeColumnDensityTrack({
    required this.trackHeight,
    required this.columnCount,
    required this.onColumnCountChanged,
    required this.color,
  });

  final double trackHeight;
  final int columnCount;
  final ValueChanged<int> onColumnCountChanged;
  final Color color;

  static const _trackWidth = 8.0;
  static const _thumbSize = 14.0;

  @override
  State<_LandscapeColumnDensityTrack> createState() =>
      _LandscapeColumnDensityTrackState();
}

class _LandscapeColumnDensityTrackState
    extends State<_LandscapeColumnDensityTrack> {
  double? _dragFraction;

  double get _fractionFromCount =>
      (widget.columnCount - kLandscapeColumnCountMin) /
      (kLandscapeColumnCountMax - kLandscapeColumnCountMin);

  int _countFromFraction(double fraction) {
    final span = kLandscapeColumnCountMax - kLandscapeColumnCountMin;
    return (kLandscapeColumnCountMin + fraction * span)
        .round()
        .clamp(kLandscapeColumnCountMin, kLandscapeColumnCountMax);
  }

  void _applyLocalDy(double dy, double trackHeight) {
    final usable = (trackHeight - _LandscapeColumnDensityTrack._thumbSize)
        .clamp(1.0, double.infinity);
    final fraction = (dy / usable).clamp(0.0, 1.0);
    final next = _countFromFraction(fraction);
    if (next != widget.columnCount) {
      widget.onColumnCountChanged(next);
    }
    setState(() => _dragFraction = fraction);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = _dragFraction ?? _fractionFromCount;
    final trackH = widget.trackHeight;
    final thumbTravel =
        (trackH - _LandscapeColumnDensityTrack._thumbSize).clamp(0.0, trackH);
    final thumbTop = fraction * thumbTravel;
    final fillH = thumbTop + _LandscapeColumnDensityTrack._thumbSize / 2;

    return Semantics(
      slider: true,
      label: '拖动调整大小',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          _applyLocalDy(box.globalToLocal(d.globalPosition).dy, trackH);
        },
        onVerticalDragUpdate: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          _applyLocalDy(box.globalToLocal(d.globalPosition).dy, trackH);
        },
        onVerticalDragEnd: (_) => setState(() => _dragFraction = null),
        onVerticalDragCancel: () => setState(() => _dragFraction = null),
        child: SizedBox(
          width: 36,
          height: trackH,
          child: Center(
            child: SizedBox(
              width: _LandscapeColumnDensityTrack._trackWidth,
              height: trackH,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: widget.color.withValues(alpha: 0.14),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: fillH.clamp(0.0, trackH),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: widget.color.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                  Positioned(
                    top: thumbTop,
                    left: (_LandscapeColumnDensityTrack._trackWidth -
                            _LandscapeColumnDensityTrack._thumbSize) /
                        2,
                    child: Container(
                      width: _LandscapeColumnDensityTrack._thumbSize,
                      height: _LandscapeColumnDensityTrack._thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.88),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 横屏左栏：头像 + 昵称 + 月龄竖排（全高；高度不足时尾部省略）。
class _PredictionLandscapeIdentityRail extends StatelessWidget {
  const _PredictionLandscapeIdentityRail({
    required this.nickname,
    required this.ageText,
    required this.babyId,
    required this.sex,
    required this.color,
    this.onAvatarTap,
  });

  final String nickname;
  final String ageText;
  final String babyId;
  final BabySex sex;
  final Color color;
  final VoidCallback? onAvatarTap;

  static List<String> _chars(String s) {
    return s.runes.map(String.fromCharCode).toList(growable: false);
  }

  static int _maxVerticalChars(double height, TextStyle? style) {
    final lineH = (style?.fontSize ?? 12) * (style?.height ?? 1.15);
    if (lineH <= 0 || height <= 0) return 0;
    return (height / lineH).floor();
  }

  Widget _verticalRun({
    required String text,
    required TextStyle? style,
    int? maxChars,
  }) {
    var chars = _chars(text);
    if (maxChars != null && chars.length > maxChars) {
      chars = chars.sublist(0, maxChars);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in chars)
          Text(ch, style: style, textAlign: TextAlign.center),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.15,
        );
    final ageStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color.withValues(alpha: 0.65),
          height: 1.15,
        );
    final showAge = ageText.trim().isNotEmpty;

    return SizedBox(
      width: 48,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 12, 4, 8),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const avatarBlock = 36.0 + 8.0;
                  final titleLineH = (titleStyle?.fontSize ?? 16) *
                      (titleStyle?.height ?? 1.15);
                  final ageLineH =
                      (ageStyle?.fontSize ?? 12) * (ageStyle?.height ?? 1.15);
                  final nickTotal = _chars(nickname).length;
                  var nickMax = nickTotal;
                  var ageMax = showAge ? _chars(ageText.trim()).length : 0;
                  final ageHeader = showAge ? 10.0 + ageLineH + 6.0 : 0.0;

                  var nickH = nickMax * titleLineH;
                  var ageH = ageHeader + ageMax * ageLineH;
                  var total = avatarBlock + nickH + ageH;

                  if (total > constraints.maxHeight && showAge) {
                    final budget = (constraints.maxHeight -
                            avatarBlock -
                            nickH -
                            ageHeader)
                        .clamp(0.0, double.infinity);
                    ageMax = _maxVerticalChars(budget, ageStyle)
                        .clamp(0, _chars(ageText.trim()).length);
                    ageH = ageHeader + ageMax * ageLineH;
                    total = avatarBlock + nickH + ageH;
                  }

                  if (total > constraints.maxHeight) {
                    final budget = (constraints.maxHeight - avatarBlock - ageH)
                        .clamp(0.0, double.infinity);
                    nickMax = _maxVerticalChars(budget, titleStyle)
                        .clamp(0, nickTotal);
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BabyAvatar(
                        babyId: babyId,
                        sex: sex,
                        radius: 18,
                        onTap: onAvatarTap,
                      ),
                      const SizedBox(height: 8),
                      _verticalRun(
                        text: nickname,
                        style: titleStyle,
                        maxChars: nickMax > 0 ? nickMax : null,
                      ),
                      if (showAge && ageMax > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          '·',
                          style:
                              ageStyle?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        _verticalRun(
                          text: ageText.trim(),
                          style: ageStyle,
                          maxChars: ageMax,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 最近未超时事件大图：持续心跳缩放。
class _HeartbeatLogo extends StatefulWidget {
  const _HeartbeatLogo({
    required this.definition,
    required this.size,
  });

  final EventDefinition? definition;
  final double size;

  @override
  State<_HeartbeatLogo> createState() => _HeartbeatLogoState();
}

class _HeartbeatLogoState extends State<_HeartbeatLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: EventLogo(definition: widget.definition, size: widget.size),
    );
  }
}

/// 事件色实心按钮：可点时持续心跳；忙碌时静止。
class _HeartbeatAccentButton extends StatefulWidget {
  const _HeartbeatAccentButton({
    required this.accent,
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final Color accent;
  final bool busy;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_HeartbeatAccentButton> createState() => _HeartbeatAccentButtonState();
}

class _HeartbeatAccentButtonState extends State<_HeartbeatAccentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _syncAnim();
  }

  @override
  void didUpdateWidget(covariant _HeartbeatAccentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) _syncAnim();
  }

  void _syncAnim() {
    if (widget.busy) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.busy ? null : widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: widget.accent,
          foregroundColor: AppColor.onPrimary(context),
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(widget.busy ? '…' : widget.label),
      ),
    );
    if (widget.busy) return button;
    return ScaleTransition(scale: _scale, child: button);
  }
}

/// 计时中「停止」：可点时持续心跳；忙碌时静止。
class _HeartbeatStopButton extends StatelessWidget {
  const _HeartbeatStopButton({
    required this.accent,
    required this.busy,
    required this.onPressed,
  });

  final Color accent;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _HeartbeatAccentButton(
      accent: accent,
      busy: busy,
      label: '停止',
      onPressed: onPressed,
    );
  }
}

class _PredictionEventCard extends ConsumerStatefulWidget {
  const _PredictionEventCard({
    required this.row,
    required this.definition,
    required this.logoAnchorKey,
    required this.now,
    required this.chartLoading,
    required this.compact,
    required this.heartbeat,
    required this.chartPoints,
    required this.pastDaysBeforeToday,
    required this.showYAxis,
    required this.relativeText,
    this.titleInlineLogo = false,
    this.activeTiming,
    this.landscapeMetrics,
    this.onToggle,
    this.onCardTap,
  });

  final SmartPredictionRow row;
  final EventDefinition? definition;

  /// 当前展示 EventLogo 槽（计时叶子 / 普通根图共用）。
  final GlobalKey logoAnchorKey;
  final DateTime now;
  final bool chartLoading;
  // 是否紧凑布局
  final bool compact;
  final bool heartbeat;
  final List<DateTime> chartPoints;
  final int pastDaysBeforeToday;
  final bool showYAxis;
  final String? relativeText;

  /// 手机横屏非首行：标题旁小 logo，隐藏倒计时上方大图。
  final bool titleInlineLogo;

  /// 网格计时中：非 null 时走 active chrome（列表态忽略）。
  final HistoryRecord? activeTiming;

  /// 横屏 compact：按列宽 scale 的尺寸表；竖屏 grid 为 null。
  final PredictionLandscapeCardMetrics? landscapeMetrics;

  /// null 时禁用推演开关（冷态骨架）。
  final ValueChanged<bool>? onToggle;

  /// 仅网格态：整卡加事件；冷态引导登录/绑定。
  final VoidCallback? onCardTap;

  @override
  ConsumerState<_PredictionEventCard> createState() =>
      _PredictionEventCardState();
}

class _PredictionEventCardState extends ConsumerState<_PredictionEventCard> {
  var _stopping = false;
  var _recallBusy = false;

  /// 热态单事件样本不足：仅间隔 Sheet 写回忆种子（不写喂养历史）。
  Future<void> _onPickIntervalRecall({
    required EventDefinition? definition,
    required String eventName,
  }) async {
    final row = widget.row;
    final lastAt = row.lastAt;
    if (lastAt == null || _recallBusy) return;
    final minutes = await pickRecallIntervalMinutes(
      context,
      definition: definition,
      eventName: eventName,
    );
    if (!mounted || minutes == null) return;
    final interval = Duration(minutes: minutes);
    if (interval < kMinIntervalForPrediction) {
      showAppToast('间隔至少 15 分钟', tone: AppToastTone.error);
      return;
    }
    setState(() => _recallBusy = true);
    try {
      final seed = PredictionRecallSeed(
        rootEventId: row.eventId,
        leafEventId: row.eventId,
        lastAt: lastAt,
        interval: interval,
        occurrenceAts:
            synthesizeOccurrenceAts(lastAt: lastAt, interval: interval),
      );
      await ref.read(predictionRecallSeedsProvider.notifier).upsertSeed(seed);
      if (!mounted) return;
      // 走父级 onToggle 闸（满额弹框）；无开关时不强制开启。
      widget.onToggle?.call(true);
      showAppToast('已记录大概间隔', tone: AppToastTone.success);
    } finally {
      if (mounted) setState(() => _recallBusy = false);
    }
  }

  Color _rootAccent(BuildContext context) {
    final parsed = _parseHex(widget.row.colorHex);
    return parsed ?? Theme.of(context).colorScheme.primary;
  }

  static Color? _parseHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  Future<void> _onStop(HistoryRecord record) async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await stopActiveTimingRecord(ref: ref, record: record);
    if (mounted) setState(() => _stopping = false);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final definition = widget.definition;
    final now = widget.now;
    final compact = widget.compact;
    final enabled = row.forecastEnabled;
    final pred = row.prediction;
    // 计时中仅网格：名旁小 logo + elapsed + 停止
    final showActiveTiming = compact && widget.activeTiming != null;
    // 计时中：叶子图/名/色；目录不可解析则回退根
    final catalog = showActiveTiming
        ? ref.watch(eventCatalogProvider).items
        : const <EventDefinition>[];
    final leafDef = showActiveTiming
        ? lookupEventForRecord(catalog, widget.activeTiming!)
        : null;
    final titleDef = showActiveTiming ? (leafDef ?? definition) : definition;
    final titleName = showActiveTiming
        ? ((leafDef?.name.trim().isNotEmpty ?? false)
            ? leafDef!.name.trim()
            : (widget.activeTiming!.eventName.trim().isNotEmpty
                ? widget.activeTiming!.eventName.trim()
                : row.eventName))
        : row.eventName;
    // 叶子可解析用叶子色；否则回退根行 colorHex
    final accent = showActiveTiming
        ? (leafDef != null
            ? resolveEventColor(context, leafDef)
            : _rootAccent(context))
        : _rootAccent(context);
    // 列表 / 计时中 / 手机横屏后列：标题旁小 logo；首列瀑布流仍用倒计时上方大图
    final m = widget.landscapeMetrics;
    final titleLogoSize = m?.titleLogoSize ?? 28.0;
    final heroLogoSize = m?.heroLogoSize ?? 52.0;
    final chartH = 96.0;
    final switchScale = m?.switchScale ?? (compact ? 0.72 : 0.8);
    final switchColumnWidth = m?.switchColumnWidth ??
        (PredictionLandscapeCardMetrics.baselineSwitchWidth * switchScale);
    final switchColumnHeight = m?.switchColumnHeight ??
        (PredictionLandscapeCardMetrics.baselineSwitchHeight * switchScale);
    final captionRowGap = m?.captionRowGap ?? 6.0;
    final titleFontSize = m?.titleFontSize ?? (compact ? 14.0 : 16.0);
    final relativeFontSize = m?.relativeFontSize ?? (compact ? 12.0 : 13.0);
    final captionFontSize = m?.captionFontSize ?? 10.0;
    final countdownFontSize = m?.countdownFontSize ?? 26.0;
    final titleLogoGap = m?.titleLogoGap ?? 8.0;
    final sectionGapSm = m?.sectionGapSm ?? 4.0;
    final sectionGapMd = m?.sectionGapMd ?? 10.0;
    final sectionGapLg = m?.sectionGapLg ?? 12.0;
    final heroGap = m?.heroGap ?? 8.0;
    final cardBorderRadius = m?.cardBorderRadius ??
        PredictionLandscapeCardMetrics.baselineCardBorderRadius;
    final toggleCaption = '${enabled ? "关闭" : "开启"}$titleName预测';
    final overdue = pred != null && pred.isOverdue(now);
    // 热态卡片展示上次时刻；计时中/骨架（onToggle==null）豁免。
    final showLastOccurrence = !showActiveTiming && widget.onToggle != null;
    final lastOccurrenceLabel = showLastOccurrence
        ? formatPredictionLastOccurrenceLabel(titleName, row.lastAt, now)
        : null;
    // 瀑布流倒计时文案（停表见 formatPredictionCountdownHms）
    final countdown = (pred == null || showActiveTiming)
        ? null
        : formatPredictionCountdownHms(pred.nextAt, now, overdue: overdue);
    final activeElapsed = showActiveTiming
        ? formatActiveTimerElapsed(
            now.difference(activeTimingStartAt(widget.activeTiming!)),
          )
        : null;
    // 大 logo：仅普通 compact 且非后列侧 logo
    final showHeroLogo = compact &&
        !showActiveTiming &&
        !widget.titleInlineLogo &&
        enabled &&
        pred != null &&
        countdown != null;
    // 空库量身定做进行中时不展示 per-card CTA，避免与 Dialog 重复写种子
    final recallSession = ref.watch(predictionRecallSessionActiveProvider);
    final emptyEligible =
        ref.watch(predictionRecallEmptyHistoryEligibleProvider);
    final gapRoots = ref.watch(predictionRecallGapRootsProvider);
    final recallDismissed = ref.watch(predictionRecallFinaleDismissedProvider);
    final recallBlocksPerCard = recallSession ||
        (emptyEligible && gapRoots.isNotEmpty && !recallDismissed);
    final showIntervalRecall = enabled &&
        !showActiveTiming &&
        pred == null &&
        row.lastAt != null &&
        widget.onToggle != null &&
        !recallBlocksPerCard;

    // 标题旁 logo：列表、计时中、或手机后列紧凑
    final showTitleLogo = !showHeroLogo;
    final content = Opacity(
      opacity: (enabled || showActiveTiming) ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showTitleLogo) ...[
                    KeyedSubtree(
                      key: widget.logoAnchorKey,
                      child: (widget.heartbeat && !showActiveTiming)
                          ? _HeartbeatLogo(
                              definition: titleDef,
                              size: titleLogoSize,
                            )
                          : EventLogo(
                              definition: titleDef, size: titleLogoSize),
                    ),
                    SizedBox(width: titleLogoGap),
                  ],
                  Expanded(
                    child: Text(
                      titleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textOnPanelGlass(context),
                      ),
                    ),
                  ),
                  // 当没有预测数据的时候，不展示开关
                  Tooltip(
                    message: '预测推演',
                    child: SizedBox(
                      width: switchColumnWidth,
                      height: switchColumnHeight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch.adaptive(
                          value: enabled,
                          onChanged: widget.onToggle,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.relativeText != null)
                    Expanded(
                      child: Text(
                        widget.relativeText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: relativeFontSize,
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const Expanded(flex: 0, child: SizedBox.shrink()),
                  SizedBox(width: captionRowGap),
                  if (pred != null) ...[
                    Expanded(
                      child: Text(
                        toggleCaption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: captionFontSize,
                          color: accent.withAlpha(153),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (lastOccurrenceLabel != null) ...[
                SizedBox(height: sectionGapSm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lastOccurrenceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: captionFontSize,
                      color: accent,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
              if (showIntervalRecall) ...[
                SizedBox(height: sectionGapMd),
                _HeartbeatAccentButton(
                  accent: accent,
                  busy: _recallBusy,
                  label: '补充大概多久一次',
                  onPressed: () => unawaited(_onPickIntervalRecall(
                    definition: titleDef ?? definition,
                    eventName: titleName,
                  )),
                ),
              ],
            ],
          ),
          if (showActiveTiming && activeElapsed != null) ...[
            SizedBox(height: sectionGapLg),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  activeElapsed,
                  style: TextStyle(
                    fontSize: countdownFontSize,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: sectionGapMd),
            // 停止独立命中 + 可点时心跳
            _HeartbeatStopButton(
              accent: accent,
              busy: _stopping,
              onPressed: () => unawaited(_onStop(widget.activeTiming!)),
            ),
          ] else ...[
            if (enabled && pred != null && compact && countdown != null) ...[
              SizedBox(height: sectionGapMd),
              // 首列（或非手机后列）：倒计时上方居中大图
              if (showHeroLogo) ...[
                Center(
                  child: KeyedSubtree(
                    key: widget.logoAnchorKey,
                    child: widget.heartbeat
                        ? _HeartbeatLogo(
                            definition: definition,
                            size: heroLogoSize,
                          )
                        : EventLogo(
                            definition: definition,
                            size: heroLogoSize,
                          ),
                  ),
                ),
                SizedBox(height: heroGap),
              ],
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '距离下次$titleName倒计时',
                    style: TextStyle(
                      fontSize: captionFontSize,
                      color: accent.withAlpha(153),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: sectionGapSm),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        countdown,
                        style: TextStyle(
                          fontSize: countdownFontSize,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (enabled && pred != null && !compact) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: chartH,
                child: widget.chartLoading
                    ? Center(
                        child: Text(
                          '正在加载中',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColor.textOnPanelGlassMuted(context),
                          ),
                        ),
                      )
                    : _LookbackChart(
                        points: widget.chartPoints,
                        now: now,
                        accent: accent,
                        anchorTod: pred.nextAt,
                        pastDaysBeforeToday: widget.pastDaysBeforeToday,
                        showYAxis: widget.showYAxis,
                      ),
              ),
            ],
          ],
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            m?.paddingLeft ?? (compact ? 10 : 14),
            m?.paddingTop ?? (compact ? 8 : 10),
            m?.paddingRight ?? (compact ? 6 : 8),
            m?.paddingBottom ?? (compact ? 10 : 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            border: Border.all(color: AppColor.divider(context)),
            // 事件品牌色经 accent 注入 panelGlass（α 在原子内）
            gradient: AppColor.panelGlassGradient(context, accent: accent),
          ),
          child: widget.onCardTap == null
              ? content
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onCardTap,
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 每日一点：解释 [anchorTod]；[pastDaysBeforeToday] 控制 X 窗。
class _LookbackChart extends StatelessWidget {
  const _LookbackChart({
    required this.points,
    required this.now,
    required this.accent,
    required this.anchorTod,
    required this.pastDaysBeforeToday,
    required this.showYAxis,
  });

  final List<DateTime> points;
  final DateTime now;
  final Color accent;
  final DateTime anchorTod;
  final int pastDaysBeforeToday;
  final bool showYAxis;

  static double _yAxisStep(double minY, double maxY) {
    final span = (maxY - minY).abs();
    if (span <= 0) return 60;
    final raw = span / 2;
    const candidates = <double>[15, 30, 60, 90, 120, 180, 240, 360, 480, 720];
    for (final c in candidates) {
      if (c + 1e-6 >= raw) return c;
    }
    return raw;
  }

  static String _fmtMinutes(double minutes) {
    var total = minutes.round();
    if (total < 0) total = 0;
    if (total >= 24 * 60) total = 24 * 60 - 1;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// X 轴日标签：今天/昨天/前天，更早用 M/d（列表前 4 日与网格三日共用）。
  static String _xAxisDayLabel(DateTime day, DateTime today) {
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final maxDayIndex = pastDaysBeforeToday.toDouble();
    final day0 = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: pastDaysBeforeToday));
    final today = DateTime(now.year, now.month, now.day);
    final pastSpots = <FlSpot>[];
    FlSpot? todaySpot;

    for (final t in points) {
      final day = DateTime(t.year, t.month, t.day);
      final dayIndex = day.difference(day0).inDays.toDouble();
      if (dayIndex < 0 || dayIndex > maxDayIndex) continue;
      final minutes = t.hour * 60 + t.minute + t.second / 60.0;
      final spot = FlSpot(dayIndex, minutes);
      if (day == today) {
        todaySpot = spot;
      } else {
        pastSpots.add(spot);
      }
    }
    pastSpots.sort((a, b) => a.x.compareTo(b.x));

    if (pastSpots.isEmpty && todaySpot == null) {
      return Center(
        child: Text(
          pastDaysBeforeToday <= 2 ? '近 3 日暂无可比时刻' : '近 7 日暂无可比时刻',
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final allSpots = <FlSpot>[...pastSpots, if (todaySpot != null) todaySpot];
    final anchorM = (anchorTod.hour * 60 + anchorTod.minute).toDouble();
    var minY = allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    var maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    minY = (minY < anchorM ? minY : anchorM) - 90;
    maxY = (maxY > anchorM ? maxY : anchorM) + 90;
    if (minY < 0) minY = 0;
    if (maxY > 24 * 60) maxY = 24 * 60;
    if (maxY - minY < 180) {
      minY = (anchorM - 90).clamp(0, 24 * 60);
      maxY = (anchorM + 90).clamp(0, 24 * 60);
    }
    final yStep = _yAxisStep(minY, maxY);
    final alignedMax = minY + 2 * yStep;
    if (alignedMax > maxY && alignedMax <= 24 * 60) {
      maxY = alignedMax;
    }
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final bars = <LineChartBarData>[];
    if (pastSpots.isNotEmpty) {
      bars.add(
        LineChartBarData(
          spots: pastSpots,
          isCurved: false,
          color: accent,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: 3.5,
              color: accent,
              strokeWidth: 0,
            ),
          ),
        ),
      );
    }
    final todayOnly = todaySpot;
    if (todayOnly != null && pastSpots.isNotEmpty) {
      bars.add(
        LineChartBarData(
          spots: [pastSpots.last, todayOnly],
          isCurved: false,
          color: accent,
          barWidth: 2,
          dashArray: const [6, 4],
          dotData: FlDotData(
            show: true,
            checkToShowDot: (s, _) =>
                (s.x - todayOnly.x).abs() < 1e-6 &&
                (s.y - todayOnly.y).abs() < 1e-6,
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: 3.5,
              color: accent,
              strokeWidth: 0,
            ),
          ),
        ),
      );
    } else if (todayOnly != null) {
      bars.add(
        LineChartBarData(
          spots: [todayOnly],
          isCurved: false,
          color: accent,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: 3.5,
              color: accent,
              strokeWidth: 0,
            ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxDayIndex,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: showYAxis,
          horizontalInterval: yStep,
          verticalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (v, _) {
                if (v < 0 || v > maxDayIndex || v != v.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                final d = day0.add(Duration(days: v.toInt()));
                final label = _xAxisDayLabel(d, today);
                // 网格窄卡：相对日两字略宽于 M/d，略降字号减少裁切
                final fontSize = pastDaysBeforeToday <= 2 ? 8.0 : 9.0;
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showYAxis,
              reservedSize: showYAxis ? 36 : 0,
              interval: yStep,
              getTitlesWidget: (v, meta) {
                if (!showYAxis) return const SizedBox.shrink();
                if (v < minY - 0.5 || v > maxY + 0.5) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _fmtMinutes(v),
                  style: TextStyle(
                    fontSize: 8,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: anchorM,
              color: accent.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchSpotThreshold: 18,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: accent.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
                    radius: 5,
                    color: accent,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 8,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            getTooltipColor: (_) => accent.withValues(alpha: 0.92),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return [
                for (final s in touchedSpots)
                  LineTooltipItem(
                    _fmtMinutes(s.y),
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
