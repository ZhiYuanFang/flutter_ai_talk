import 'dart:async';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/prediction_layout_store.dart';
import '../data/active_timing_stop.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import '../data/prediction_care_alert.dart';
import '../data/prediction_demo_skeleton.dart';
import '../data/smart_prediction_rows.dart';
import '../home_widget/home_widget_sync.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/clinic_ws_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/forecast_toggle_provider.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../providers/prediction_gate_provider.dart';
import '../providers/prediction_layout_provider.dart';
import '../providers/prediction_range_history_provider.dart';
import '../providers/prediction_recall_provider.dart';
import '../providers/session_provider.dart';
import '../providers/baby_display_provider.dart';
import '../providers/smart_prediction_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'event_add_actions.dart';
import 'widgets/app_modal_glass_panel.dart';
import 'event_logo.dart';
import 'prediction_recall_onboarding_panel.dart';
import 'theme_palette_sheet.dart';
import 'widgets/app_toast.dart';
import 'widgets/baby_avatar.dart';

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
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final shell = tokens?.shellColor ?? scheme.surface;
    final realRows = ref.watch(smartPredictionRowsProvider);
    final tipAsync = ref.watch(widgetTipCardTextProvider);
    final ensureAsync = ref.watch(predictionRangeEnsureProvider);
    final rangeState = ref.watch(predictionRangeHistoryProvider);
    final catalog = ref.watch(eventCatalogProvider).items;
    final layout = ref.watch(predictionCardsLayoutProvider).asData?.value ??
        PredictionCardsLayout.grid;
    final now =
        ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
    final chartsLoading = ensureAsync.isLoading ||
        ensureAsync.isRefreshing ||
        rangeState.loading;
    // 仅「未 ready 且仍在拉」算 pending；失败/跳过后不得永久「正在加载中」
    final rangePending =
        !rangeState.ready && (rangeState.loading || chartsLoading);
    final tipText = tipAsync.asData?.value;
    final showTip = tipText != null && tipText.isNotEmpty;
    final babyDisplay = ref.watch(babyDisplayProvider);
    final onShell = tokens?.onShell ?? scheme.onSurface;
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
    final useDemoSkeleton = !loggedIn || !bound || emptyHistoryEligible;
    final mountNonce = ref.watch(predictionDemoMountNonceProvider);
    final mountNow = ref.watch(predictionDemoMountNowProvider);
    final rows = useDemoSkeleton
        ? buildPredictionDemoSkeletonRows(
            catalog: catalog,
            mountNow: mountNow,
            mountNonce: mountNonce,
          )
        : realRows;
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
        (recallSession ||
            (gapRoots.isNotEmpty && !recallDismissed))) {
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
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = true;
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
      if (prevDn.isNotEmpty && dn.isEmpty && ref.read(sessionProvider).isLoggedIn) {
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
    final showBindGate =
        gateKind == PredictionGateKind.bind && bindGateVisible;

    Future<void> openCompanion() async {
      await activateCompanionClinicWs(ref);
      if (!context.mounted) return;
      await context.push('/companion');
    }

    void openSettings() {
      if (!ref.read(sessionProvider).isLoggedIn) {
        context.push('/login');
        return;
      }
      context.push('/settings');
    }

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
    void reopenRecallGateIfNeeded() {
      if (recallSessionLive && !recallDialogVisible) {
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = true;
      }
    }

    void finishRecallOnboarding() {
      ref.read(predictionRecallFinaleDismissedProvider.notifier).state = true;
      ref.read(predictionRecallSessionActiveProvider.notifier).state = false;
      ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
      ref.read(predictionRecallSessionRootsProvider.notifier).state = const [];
    }

    // Auth 冷态（未登录/未绑定）：滑动引导大卡，不展示留意/3小时/底 tip。
    final authGuestChrome = !loggedIn || !bound;

    final Widget? careOrGuide;
    if (authGuestChrome) {
      careOrGuide = const _PredictionSwipeGuideCard();
    } else if (useDemoSkeleton) {
      careOrGuide = const _CareAlertDemoHealthyPanel();
    } else {
      final careItems = ref.watch(predictionCareAlertProvider);
      final careState = ref.watch(predictionCareAlertStateProvider);
      // 仅 isVip==true 走异常+刷新；未知/失败按非 VIP（与详情 CTA 对齐）
      final isVip = ref.watch(
        vipStatusProvider.select((async) {
          final s = async.valueOrNull;
          if (s == null) return false;
          return s.isVip;
        }),
      );
      careOrGuide = _CareAlertPanel(
        state: careState,
        items: careItems,
        isVip: isVip,
        onTapItem: (item) {
          context.push('/prediction/alert', extra: item);
        },
        onRefresh: () {
          unawaited(
            ref
                .read(predictionCareAlertStateProvider.notifier)
                .ensureLoaded(force: true),
          );
        },
        onOpenCompanion: () {
          unawaited(openCompanion());
        },
        onOpenVip: () {
          Future<void> openVip() async {
            if (kIsWeb) {
              showAppToast('请使用手机 App 开通 VIP');
              return;
            }
            await context.push<bool>('/vip/purchase');
            // 回流：刷新权益；已是会员才强制重拉日缓存
            await ref.read(vipStatusProvider.notifier).refresh();
            final status = ref.read(vipStatusProvider).valueOrNull;
            if (status?.isVip != true) return;
            await ref
                .read(predictionCareAlertStateProvider.notifier)
                .ensureLoaded(force: true);
          }

          unawaited(openVip());
        },
      );
    }

    // 网格计时中 chrome：从喂养历史匹配进行中记录
    final historyItems = ref.watch(homeHistoryProvider).items;
    // 落库飞入：按 root 挂当前展示 logo 锚点
    final logoAnchors = ref.watch(predictionLogoAnchorRegistryProvider);
    logoAnchors.retainOnly(rows.map((r) => r.eventId));

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // 横屏强制瀑布；竖屏尊重本地偏好。
    final useGridLayout =
        isLandscape || layout == PredictionCardsLayout.grid;
    // 竖屏 2；手机横屏 3；平板横屏（shortestSide≥600）5。
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isTabletLandscape = isLandscape && shortestSide >= 600;
    final waterfallColumns =
        !isLandscape ? 2 : (isTabletLandscape ? 5 : 3);
    // KeepAlive 下须结合当前 pager 页，滑离预测即释放沉浸/常亮。
    final predictionPageVisible =
        ref.watch(homePagerIndexProvider) == HomePagerPage.prediction;
    final immersiveActive =
        !kIsWeb && isLandscape && predictionPageVisible;

    Widget buildCardsBody() {
      if (rows.isEmpty) {
        return Center(
          child: Text(
            (!useDemoSkeleton && rangePending) ? '正在加载中' : '暂无可用预测数据',
            style: TextStyle(
              color: onShell.withValues(alpha: 0.55),
            ),
          ),
        );
      }
      if (useGridLayout) {
        return _WaterfallCards(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 8 : 16,
            0,
            isLandscape ? 8 : 16,
            24,
          ),
          rows: rows,
          columnCount: waterfallColumns,
          itemBuilder: (row) {
            final activeTiming = useDemoSkeleton
                ? null
                : findLatestActiveTimingForRoot(
                    items: historyItems,
                    rootEventId: row.eventId,
                    catalog: catalog,
                  );
            return _PredictionEventCard(
              row: row,
              definition: lookupEventById(catalog, row.eventId),
              logoAnchorKey: logoAnchors.keyFor(row.eventId),
              now: now,
              chartLoading: useDemoSkeleton ? false : chartsLoading,
              compact: true,
              heartbeat: row.eventId == heartbeatId,
              chartPoints: const [],
              pastDaysBeforeToday: 2,
              showYAxis: false,
              relativeText: activeTiming != null
                  ? null
                  : _relativeFor(row, now, grid: true),
              activeTiming: activeTiming,
              onToggle: useDemoSkeleton
                  ? null
                  : (v) {
                      ref
                          .read(forecastDisabledIdsProvider.notifier)
                          .setEnabled(row.eventId, v);
                    },
              // 计时中不整卡加事件，避免与停止手势冲突
              onCardTap: activeTiming != null
                  ? null
                  : () {
                      if (useDemoSkeleton) {
                        // 未登录/未绑定：复用软门闸 reopen，禁止直达路由。
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
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                    ref
                        .read(forecastDisabledIdsProvider.notifier)
                        .setEnabled(row.eventId, v);
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
            maxHeightFactor: 0.72,
            child: PredictionRecallOnboardingPanel(
              gapRoots:
                  sessionRoots.isNotEmpty ? sessionRoots : gapRoots,
              catalog: catalog,
              onFinished: finishRecallOnboarding,
            ),
          ),
        ),
    ];

    final Widget pageBody;
    if (isLandscape) {
      // 横屏：左竖排身份 + 右三列瀑布；无顶栏工具 / 留意 / 引导 / 3小时。
      pageBody = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PredictionLandscapeIdentityRail(
            nickname: nickname,
            ageText: babyDisplay.showAge ? ageText : '',
            color: onShell,
          ),
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: reopenRecallGateIfNeeded,
                  child: buildCardsBody(),
                ),
                ...gateOverlays,
              ],
            ),
          ),
        ],
      );
    } else {
      pageBody = Column(
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
                IconButton(
                  tooltip: layout == PredictionCardsLayout.grid
                      ? '切换为纵向列表'
                      : '切换为瀑布流',
                  onPressed: () {
                    reopenRecallGateIfNeeded();
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
                  onTap: reopenRecallGateIfNeeded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: careOrGuide,
                      ),
                      // Auth 冷态不展示接下来3小时；已绑定冷态/热态照旧。
                      if (!authGuestChrome && timelineText != null)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _NextThreeHoursTimeline(
                            body: timelineText,
                            onOpenFeeding: () {
                              ref
                                  .read(homePagerRequestProvider.notifier)
                                  .requestPage(HomePagerPage.feeding);
                            },
                          ),
                        ),
                      Expanded(child: buildCardsBody()),
                      if (!authGuestChrome && showTip)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _BottomTipMarquee(
                            text: tipText,
                            onTap: openCompanion,
                          ),
                        ),
                    ],
                  ),
                ),
                ...gateOverlays,
              ],
            ),
          ),
        ],
      );
    }

    return _PredictionLandscapeImmersiveHost(
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
                  Transform.translate(
                    offset: Offset(leftDx, 0),
                    child: ScaleTransition(
                      scale: _scale,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 36,
                        color: onPanel.withValues(alpha: 0.9),
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onPanel,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '左滑进广场 · 右滑去喂养',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: onPanel.withValues(alpha: 0.75),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(rightDx, 0),
                    child: ScaleTransition(
                      scale: _scale,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 36,
                        color: onPanel.withValues(alpha: 0.9),
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

/// 冷态固定健康文案（不请求接口、无详情副作用）。
class _CareAlertDemoHealthyPanel extends StatelessWidget {
  const _CareAlertDemoHealthyPanel();

  @override
  Widget build(BuildContext context) {
    return const _CareAlertShell(
      body: _CareAlertStaticLine(
        height: 44,
        text: '宝宝很健康，继续保持～',
        showChevron: false,
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
  });

  final VoidCallback onDismiss;
  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Color(0x66000000)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.sizeOf(context).height * maxHeightFactor,
                  maxWidth: 420,
                ),
                child: child,
              ),
            ),
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

/// 值得留意卡片：加载 / 空态（进陪伴）/ 失败分流 / 跑马灯。
class _CareAlertPanel extends StatelessWidget {
  const _CareAlertPanel({
    required this.state,
    required this.items,
    required this.isVip,
    required this.onTapItem,
    required this.onRefresh,
    required this.onOpenCompanion,
    required this.onOpenVip,
  });

  final PredictionCareAlertState state;
  final List<CareAlertEventItem> items;
  final bool isVip;
  final ValueChanged<CareAlertEventItem> onTapItem;
  final VoidCallback onRefresh;
  final VoidCallback onOpenCompanion;
  final VoidCallback onOpenVip;

  static const _rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    // 失败优先于 loading（force 重试时仍可能短暂 loading）
    if (state.failed && !state.loading) {
      // VIP：真异常可刷新；非 VIP：开通入口（无刷新）
      if (isVip) {
        return _CareAlertShell(
          trailing: IconButton(
            tooltip: '重新加载',
            onPressed: onRefresh,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.refresh,
              size: 20,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          body: const _CareAlertStaticLine(
            height: _rowHeight,
            text: '接口异常',
            showChevron: false,
          ),
        );
      }
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenVip,
          child: const _CareAlertShell(
            body: _CareAlertStaticLine(
              height: _rowHeight,
              text: '开通会员查看每日提醒',
              showChevron: true,
            ),
          ),
        ),
      );
    }
    // 仅真正拉取中显示加载；!ready 且未 loading（门控未放行）不当假加载
    if (state.loading) {
      return const _CareAlertShell(
        body: _CareAlertStaticLine(
          height: _rowHeight,
          text: '加载中…',
          showChevron: false,
        ),
      );
    }
    if (!state.ready) {
      return const SizedBox.shrink();
    }
    if (items.isEmpty) {
      // 空态：无「值得留意」标题；点进陪伴
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenCompanion,
          child: const _CareAlertShell(
            showTitle: false,
            body: _CareAlertStaticLine(
              height: _rowHeight,
              text: '宝宝成长得真棒！',
              showChevron: true,
            ),
          ),
        ),
      );
    }
    return _CareAlertShell(
      body: _CareAlertMarquee(
        items: items,
        rowHeight: _rowHeight,
        onTapItem: onTapItem,
      ),
    );
  }
}

/// 玻璃拟化外壳（可选标题 + 正文区）。
class _CareAlertShell extends StatelessWidget {
  const _CareAlertShell({
    required this.body,
    this.trailing,
    this.showTitle = true,
  });

  final Widget body;
  final Widget? trailing;
  final bool showTitle;

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
              if (showTitle)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '值得留意',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textOnPanelGlass(context),
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                )
              else if (trailing != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: trailing!,
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

/// 单行静态文案（空态可点进陪伴 / 加载 / 错误）。
class _CareAlertStaticLine extends StatelessWidget {
  const _CareAlertStaticLine({
    required this.height,
    required this.text,
    required this.showChevron,
  });

  final double height;
  final String text;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        // 无标题时略增上边距，避免贴边
        padding: EdgeInsets.fromLTRB(16, showChevron ? 10 : 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: AppColor.textOnPanelGlass(context),
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColor.textOnPanelGlassMuted(context),
              ),
          ],
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
  });

  final EdgeInsets padding;
  final List<SmartPredictionRow> rows;
  final Widget Function(SmartPredictionRow row) itemBuilder;
  /// 列数（竖屏 2 / 横屏 3）。
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final count = columnCount < 1 ? 1 : columnCount;
    final cols = List.generate(count, (_) => <SmartPredictionRow>[]);
    for (var i = 0; i < rows.length; i++) {
      cols[i % count].add(rows[i]);
    }
    Widget column(List<SmartPredictionRow> col) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < col.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            itemBuilder(col[i]),
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
            if (c > 0) const SizedBox(width: 12),
            Expanded(child: column(cols[c])),
          ],
        ],
      ),
    );
  }
}

/// 横屏左栏：昵称 + 月龄竖排（逐字纵向），可滚动防溢出。
class _PredictionLandscapeIdentityRail extends StatelessWidget {
  const _PredictionLandscapeIdentityRail({
    required this.nickname,
    required this.ageText,
    required this.color,
  });

  final String nickname;
  final String ageText;
  final Color color;

  static List<String> _chars(String s) {
    // 按 Unicode 标量拆字（中文昵称足够）；避免引入额外依赖。
    return s.runes.map(String.fromCharCode).toList(growable: false);
  }

  Widget _verticalRun(
    BuildContext context, {
    required String text,
    required TextStyle? style,
  }) {
    final chars = _chars(text);
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
        padding: const EdgeInsets.fromLTRB(6, 12, 4, 12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _verticalRun(context, text: nickname, style: titleStyle),
              if (showAge) ...[
                const SizedBox(height: 10),
                Text(
                  '·',
                  style: ageStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _verticalRun(context, text: ageText.trim(), style: ageStyle),
              ],
            ],
          ),
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

/// 计时中「停止」：可点时持续心跳；忙碌时静止。
class _HeartbeatStopButton extends StatefulWidget {
  const _HeartbeatStopButton({
    required this.accent,
    required this.busy,
    required this.onPressed,
  });

  final Color accent;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_HeartbeatStopButton> createState() => _HeartbeatStopButtonState();
}

class _HeartbeatStopButtonState extends State<_HeartbeatStopButton>
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
  void didUpdateWidget(covariant _HeartbeatStopButton oldWidget) {
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
        child: Text(widget.busy ? '…' : '停止'),
      ),
    );
    if (widget.busy) return button;
    return ScaleTransition(scale: _scale, child: button);
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
    this.activeTiming,
    this.onToggle,
    this.onCardTap,
  });

  final SmartPredictionRow row;
  final EventDefinition? definition;
  /// 当前展示 EventLogo 槽（计时叶子 / 普通根图共用）。
  final GlobalKey logoAnchorKey;
  final DateTime now;
  final bool chartLoading;
  final bool compact;
  final bool heartbeat;
  final List<DateTime> chartPoints;
  final int pastDaysBeforeToday;
  final bool showYAxis;
  final String? relativeText;
  /// 网格计时中：非 null 时走 active chrome（列表态忽略）。
  final HistoryRecord? activeTiming;
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
    final showActiveTiming =
        compact && widget.activeTiming != null;
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
    // 列表标题小 logo；瀑布流大图在倒计时上方；计时中用标题旁小图
    final titleLogoSize = 28.0;
    final heroLogoSize = 52.0;
    final chartH = 96.0;
    // 迷你推演开关（瀑布流 / 纵向共用）
    final switchScale = compact ? 0.72 : 0.8;
    final overdue = pred != null && pred.isOverdue(now);
    // 瀑布流倒计时文案（停表见 formatPredictionCountdownHms）
    final countdown = (pred == null || showActiveTiming)
        ? null
        : formatPredictionCountdownHms(pred.nextAt, now, overdue: overdue);
    final activeElapsed = showActiveTiming
        ? formatActiveTimerElapsed(
            now.difference(activeTimingStartAt(widget.activeTiming!)),
          )
        : null;

    final content = Opacity(
      opacity: (enabled || showActiveTiming) ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 列表 / 计时中：标题旁 logo；普通瀑布流标题行仅名+开关
              if (!compact || showActiveTiming) ...[
                KeyedSubtree(
                  key: widget.logoAnchorKey,
                  child: EventLogo(definition: titleDef, size: titleLogoSize),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  titleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textOnPanelGlass(context),
                  ),
                ),
              ),
              Tooltip(
                message: '推演',
                child: Transform.scale(
                  scale: switchScale,
                  child: Switch.adaptive(
                    value: enabled,
                    onChanged: widget.onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          if (showActiveTiming && activeElapsed != null) ...[
            const SizedBox(height: 12),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  activeElapsed,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 停止独立命中 + 可点时心跳
            _HeartbeatStopButton(
              accent: accent,
              busy: _stopping,
              onPressed: () => unawaited(_onStop(widget.activeTiming!)),
            ),
          ] else ...[
            if (enabled && widget.relativeText != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.relativeText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (enabled && pred != null && compact && countdown != null) ...[
              const SizedBox(height: 10),
              // 倒计时上方居中大图（心跳仅 soonest）
              Center(
                child: KeyedSubtree(
                  key: widget.logoAnchorKey,
                  child: widget.heartbeat
                      ? _HeartbeatLogo(
                          definition: definition,
                          size: heroLogoSize,
                        )
                      : EventLogo(definition: definition, size: heroLogoSize),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    countdown,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
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
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 14,
            compact ? 8 : 10,
            compact ? 6 : 8,
            compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
                    borderRadius: BorderRadius.circular(18),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (v, _) {
                if (v < 0 ||
                    v > maxDayIndex ||
                    v != v.roundToDouble()) {
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

/// 预测页底栏 tip：短文静止，长文横向循环滚；点击进陪伴。
class _BottomTipMarquee extends StatefulWidget {
  const _BottomTipMarquee({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_BottomTipMarquee> createState() => _BottomTipMarqueeState();
}

class _BottomTipMarqueeState extends State<_BottomTipMarquee>
    with SingleTickerProviderStateMixin {
  static const _gap = 48.0;
  static const _pxPerSec = 18.0;

  late final AnimationController _ctrl;
  var _overflow = false;
  var _textWidth = 0.0;
  var _viewWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _BottomTipMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _syncAnim();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  TextStyle _style(ColorScheme scheme) => TextStyle(
        fontSize: 14,
        height: 1.25,
        color: scheme.onSurface.withValues(alpha: 0.92),
      );

  void _measure(double viewW, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = painter.width;
    _viewWidth = viewW;
    final nextOverflow = _textWidth > _viewWidth + 0.5;
    if (nextOverflow != _overflow) {
      setState(() => _overflow = nextOverflow);
    } else {
      _overflow = nextOverflow;
    }
    _syncAnim();
  }

  void _syncAnim() {
    if (!_overflow) {
      if (_ctrl.isAnimating) _ctrl.stop();
      _ctrl.value = 0;
      return;
    }
    final distance = _textWidth + _gap;
    final ms = ((distance / _pxPerSec) * 1000).round().clamp(3000, 24000);
    if (_ctrl.duration?.inMilliseconds != ms) {
      _ctrl.duration = Duration(milliseconds: ms);
    }
    if (!_ctrl.isAnimating) {
      unawaited(_ctrl.repeat());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _style(scheme);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 布局后测量，决定静止 / 横滚
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _measure(constraints.maxWidth, style);
                  });
                  if (!_overflow) {
                    return Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: style,
                    );
                  }
                  return ClipRect(
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final offset =
                            -_ctrl.value * (_textWidth + _gap);
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Transform.translate(
                              offset: Offset(offset, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.text,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: style,
                                  ),
                                  const SizedBox(width: _gap),
                                  Text(
                                    widget.text,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: style,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
