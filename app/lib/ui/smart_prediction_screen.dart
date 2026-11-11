import 'dart:async';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pangbao_app/ui/widgets/app_glass_overlay.dart';
import 'prediction_wake_lock.dart';

import '../data/client_usage_events.dart';
import '../providers/client_usage_provider.dart';
import '../config/prediction_layout_store.dart';
import '../data/active_timing_eta.dart';
import '../data/active_timing_stop.dart';
import '../data/appointment_event.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import '../data/relative_calendar_day.dart';
import '../data/prediction_demo_skeleton.dart';
import '../data/prediction_recall_seed.dart';
import '../data/event_next_predictor.dart';
import '../data/feature_unlock_models.dart';
import '../data/smart_prediction_rows.dart';
import '../data/trend_predict_accuracy.dart';
import '../providers/settings_baby.dart';
import '../api/api_exceptions.dart';
import '../providers/appointment_last_occurrence_provider.dart';
import '../providers/appointment_next_provider.dart';
import '../providers/history_latest_by_event_provider.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/forecast_toggle_provider.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_gate_provider.dart';
import '../providers/prediction_landscape_column_provider.dart';
import '../providers/prediction_layout_provider.dart';
import '../providers/prediction_range_history_provider.dart';
import '../providers/prediction_recall_provider.dart';
import '../providers/session_provider.dart';
import '../home_widget/format_widget_relative_time.dart';
import '../providers/baby_display_provider.dart';
import '../providers/app_notification_preference_provider.dart';
import '../providers/app_push_registration_provider.dart';
import '../providers/landscape_voice_provider.dart';
import '../providers/smart_prediction_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_theme_schedule.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import '../ucg/push/ucg_push_native.dart';
import 'appointment_next_sheet.dart';
import 'event_add_actions.dart';
import 'event_record_sheet.dart';
import 'home_history_edit_sheet.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_modal_glass_panel.dart';
import 'event_logo.dart';
import 'prediction_recall_interval_picker.dart';
import '../config/prediction_landscape_column_store.dart';
import 'prediction_landscape_card_metrics.dart';
import 'landscape_voice_lifecycle_binder.dart';
import 'landscape_voice_subtitle_toast.dart';
import 'ucg_square_edge_dock.dart';
import 'theme_palette_sheet.dart';
import 'widgets/app_toast.dart';
import 'widgets/baby_avatar.dart';

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

/// 预测开关：槽位商业门闸已删除；开/关仅写本地禁用集合。
Future<bool> _requestForecastToggle({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
  required bool enable,
  required int enabledCount,
  required bool currentlyEnabled,
  required int allowedCount,
}) async {
  if (!enable) {
    await ref.read(forecastDisabledIdsProvider.notifier).setEnabled(eventId, false);
    return true;
  }
  if (currentlyEnabled) return true;
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
              foregroundColor: AppColor.onFill(context, scheme.primary),
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
        // 与思考窗共用计数，避免思考结束误关投屏常亮。
        await PredictionWakeLock.setImmersive(true);
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
      await PredictionWakeLock.setImmersive(false);
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
    // 挂载预测页时预取预约 nextAt（catalog 变化会重跑）
    ref.watch(appointmentNextPrefetchProvider);
    // 批量最近发生（预测卡 / 预约「上一次」主源）
    ref.watch(historyLatestByEventPrefetchProvider);
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
    // 冷态骨架：仅未登录 / 未绑定；已绑定空历史走热态目录完备行
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
    // 永久可开启条数；开关闸按「已开启计数」占用，非排序下标。
    final featureCatalog = ref.watch(featureCatalogStateProvider);
    final enabledCount = rows.where((r) => r.forecastEnabled).length;
    // 槽位能力已删除：不再按 allowedCount 热态裁剪已开启项。
    Future<void> onForecastToggle(String eventId, bool enable) async {
      final currentlyEnabled =
          rows.any((r) => r.eventId == eventId && r.forecastEnabled);
      final ok = await _requestForecastToggle(
        context: context,
        ref: ref,
        eventId: eventId,
        enable: enable,
        enabledCount: enabledCount,
        currentlyEnabled: currentlyEnabled,
        allowedCount: -1,
      );
      if (!ok) return;
      // 列表数据序：rows 下标 + 1；描述含事件显示名。
      final order = rows.indexWhere((r) => r.eventId == eventId) + 1;
      if (order <= 0) return;
      final label = lookupEventById(catalog, eventId)?.name ?? eventId;
      unawaited(
        ref.read(clientUsageReporterProvider).reportEvent(
              enable
                  ? ClientUsageEvents.predictionToggleOn(
                      order: order,
                      eventLabel: label,
                    )
                  : ClientUsageEvents.predictionToggleOff(
                      order: order,
                      eventLabel: label,
                    ),
            ),
      );
    }
    final heartbeatId = soonestHeartbeatEventId(rows, now);
    final timelineText = buildNextThreeHoursTimelineText(rows, now);
    final loginGateVisible = ref.watch(predictionLoginGateVisibleProvider);
    final bindGateVisible = ref.watch(predictionBindGateVisibleProvider);

    // 门闸优先级：未登录 > 未绑定（量身定做 Dialog 已退役）
    final PredictionGateKind gateKind;
    if (!loggedIn) {
      gateKind = PredictionGateKind.login;
    } else if (!bound) {
      gateKind = PredictionGateKind.bind;
    } else {
      gateKind = PredictionGateKind.none;
    }

    // 残留量身定做会话：一律关闭（Dialog 已退役）
    final recallSessionLingering =
        ref.watch(predictionRecallSessionActiveProvider) ||
            ref.watch(predictionRecallDialogVisibleProvider);
    if (recallSessionLingering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(predictionRecallSessionActiveProvider.notifier).state = false;
        ref.read(predictionRecallDialogVisibleProvider.notifier).state = false;
        ref.read(predictionRecallSessionRootsProvider.notifier).state =
            const [];
      });
    }

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
      }
    }

    /// 骨架卡等意图入口：可打开登录/绑定门闸。
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
      }
    }

    // Auth 冷态（未登录/未绑定）：滑动引导大卡，不展示3小时。
    final authGuestChrome = !loggedIn || !bound;

    // 值得留意已迁至 AI 分析页；热态不再展示留意卡。
    final Widget? careOrGuide =
        authGuestChrome ? const _PredictionSwipeGuideCard() : null;

    // 网格计时中 chrome：从喂养历史匹配进行中记录
    final historyItems = ref.watch(homeHistoryProvider).items;
    final rangeHistoryItems = ref.watch(predictionRangeHistoryProvider).items;
    // 进行中 ETA：duration 样本用月龄半衰期
    final babyBirth = ref.watch(settingsBabyProvider).asData?.value.birthDate ??
        DateTime(now.year, 1, 1);
    DateTime? etaForActive(HistoryRecord? active, String rootId) {
      if (active == null || useDemoSkeleton) return null;
      return expectEndAtForActiveTiming(
        active: active,
        rootEventId: rootId,
        homeItems: historyItems,
        rangeItems: rangeHistoryItems,
        catalog: catalog,
        now: now,
        birthDate: babyBirth,
      );
    }

    // 落库飞入：按 root 挂当前展示 logo 锚点
    final logoAnchors = ref.watch(predictionLogoAnchorRegistryProvider);
    logoAnchors.retainOnly(rows.map((r) => r.eventId));

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // 竖屏通知引导：未授权且偏好开且本会话未关。
    final notifPrefOn =
        ref.watch(appNotificationPreferenceProvider).asData?.value ?? true;
    final notifAuth =
        ref.watch(osNotificationAuthProvider).asData?.value;
    final notifBannerDismissed =
        ref.watch(notificationOptInBannerDismissedProvider);
    final showNotifOptInBanner = !isLandscape &&
        shouldShowNotificationOptInBanner(
          loggedIn: loggedIn,
          preferenceEnabled: notifPrefOn,
          osAuth: notifAuth,
          sessionDismissed: notifBannerDismissed,
        );
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

    // 广场资格开通后：预测竖屏贴边入口球（横屏/喂养不挂）
    // 桌面小组件入口已上移主壳 EdgeDock，本页不再垫 FAB 底
    final showUcgSquareBall = kUcgHomePagerEnabled &&
        !isLandscape &&
        predictionPageVisible &&
        ref.watch(ucgEligibilityStateProvider).isQualified;
    const cardsBottomPad = 24.0;

    // 横屏 chip 仍在本页；竖屏球已上移主壳，此处不再因竖屏 flag watch
    final landscapeVoice = (isLandscape && kPredictionLandscapeVoiceEnabled)
        ? ref.watch(landscapeVoiceControllerProvider)
        : null;

    // 下拉：home 第 1 页 + range force + latest-by-event（手势清冷却）；
    // Toast 仅看 home/range；指示器等三路 settle；不 clear latest 缓存
    Future<void> onCardsPullRefresh() async {
      resetHistoryLatestByEventCooldownForUserGesture();
      final homeFut = ref.read(homeHistoryProvider.notifier).refreshFromRemote();
      final rangeFut =
          ref.read(predictionRangeHistoryProvider.notifier).reloadForUserPull();
      // 与窗刷新并行；成败不单独 Toast
      final latestFut = requestHistoryLatestByEventSync(ref);
      final results = await Future.wait<bool>([homeFut, rangeFut]);
      await latestFut;
      if (!results.every((ok) => ok)) {
        showAppToast('刷新失败，请稍后重试', tone: AppToastTone.error);
      }
    }

    Widget wrapCardsRefresh(Widget child) {
      return RefreshIndicator(
        onRefresh: onCardsPullRefresh,
        child: child,
      );
    }

    Widget buildCardsBody() {
      // 空态也须可拉：AlwaysScrollable + 撑满高度
      if (rows.isEmpty) {
        return wrapCardsRefresh(
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(
                      rangePending ? '正在加载中' : '暂无可用预测事件',
                      style: TextStyle(
                        color: onShell.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
      // 竖屏热态：整卡长按切换 list↔grid（与 AppBar 同源）；横屏 / 骨架不参与
      final VoidCallback? onLongPressLayoutToggle =
          (useDemoSkeleton || isLandscape)
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  final next = layout == PredictionCardsLayout.grid
                      ? PredictionCardsLayout.list
                      : PredictionCardsLayout.grid;
                  unawaited(
                    ref
                        .read(predictionCardsLayoutProvider.notifier)
                        .setLayout(next)
                        .then((_) {
                      return ref.read(clientUsageReporterProvider).reportEvent(
                            next == PredictionCardsLayout.list
                                ? ClientUsageEvents.predictionLayoutToList()
                                : ClientUsageEvents.predictionLayoutToGrid(),
                          );
                    }),
                  );
                };

      // 热态加事件：关推演永远 add；开推演无 lastAt 仍 supplement；计时中不可点
      VoidCallback? addEventTapFor(SmartPredictionRow row,
          {HistoryRecord? activeTiming}) {
        if (activeTiming != null) return null;
        if (useDemoSkeleton) {
          return () {
            if (!loggedIn || !bound) {
              openGateFromIntent();
              return;
            }
            showAppToast('登录并绑定后即可记录喂养');
          };
        }
        return () {
          final def = lookupEventById(catalog, row.eventId);
          if (def == null) return;
          // 关推演：永远 add（含无 lastAt）；开推演：无 lastAt → supplement
          final isSupplement =
              row.forecastEnabled && row.lastAt == null;
          unawaited(
            handleEventGridTap(
              context: context,
              ref: ref,
              event: def,
              // add/supplement 均统一记录 sheet（无确认框、无即时 now）
              intent: isSupplement
                  ? EventRecordIntent.supplement
                  : EventRecordIntent.add,
            ),
          );
        };
      }

      // 「上一次」点按：预约再 filter 开编辑；非预约仅近窗有真记录可点
      VoidCallback? editLastTapFor(SmartPredictionRow row) {
        if (useDemoSkeleton) return null;
        final isAppt = catalogRootIsAppointment(row.eventId, catalog);
        if (isAppt) {
          // 有展示上次行即可点；点按再拉，不依赖近窗
          return () {
            unawaited(() async {
              final rec = await fetchAppointmentLastHistoryRecord(
                ref,
                row.eventId,
                catalogOverride: catalog,
              );
              if (!context.mounted) return;
              if (rec == null) {
                showAppToast('暂无法打开编辑，请稍后重试', tone: AppToastTone.error);
                return;
              }
              await showHomeHistoryEditSheet(
                context,
                record: rec,
                eventCatalog: catalog,
                history: ref.read(homeHistoryProvider.notifier),
              );
            }());
          };
        }
        // 有 pred：同桶最新；无 pred：根下最新
        final record = row.prediction != null
            ? latestRealHistoryRecordForPredictionBucketFromSources(
                bucketEventId: row.prediction!.eventId,
                catalog: catalog,
                homeItems: historyItems,
                rangeItems: rangeHistoryItems,
              )
            : latestRealHistoryRecordForRootFromSources(
                rootEventId: row.eventId,
                catalog: catalog,
                homeItems: historyItems,
                rangeItems: rangeHistoryItems,
              );
        if (record == null) return null;
        return () {
          unawaited(
            showHomeHistoryEditSheet(
              context,
              record: record,
              eventCatalog: catalog,
              history: ref.read(homeHistoryProvider.notifier),
            ),
          );
        };
      }

      // 竖列表准确率：合并真历史按根聚合（不计回忆种子）
      final accuracyByRoot = useDemoSkeleton
          ? const <String, List<HistoryRecord>>{}
          : groupHistoryByRootEvent(
              history: mergeRealHistoryById(
                rangeItems: rangeHistoryItems,
                homeItems: historyItems,
              ),
              catalog: catalog,
            );

      if (useGridLayout) {
        Widget buildGrid({PredictionLandscapeCardMetrics? metrics}) {
          return wrapCardsRefresh(
            _WaterfallCards(
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
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (row, columnIndex, rowIndexInColumn) {
                final activeTiming = useDemoSkeleton
                    ? null
                    : findLatestActiveTimingForRoot(
                        items: historyItems,
                        rootEventId: row.eventId,
                        catalog: catalog,
                      );
                final titleInlineLogo = phoneLandscape && rowIndexInColumn > 0;
                // 非合并胜出子：logo/色跟 prediction.eventId；标题用根 row.eventName
                final brandId = row.prediction?.eventId ?? row.eventId;
                return _PredictionEventCard(
                  row: row,
                  definition: lookupEventById(catalog, brandId),
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
                  activeExpectEndAt: etaForActive(activeTiming, row.eventId),
                  landscapeMetrics: metrics,
                  onToggle: useDemoSkeleton
                      ? null
                      : (v) {
                          unawaited(onForecastToggle(row.eventId, v));
                        },
                  onCardTap: addEventTapFor(row, activeTiming: activeTiming),
                  onLongPressLayout: onLongPressLayoutToggle,
                  onEditLastOccurrence: editLastTapFor(row),
                );
              },
            ),
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
      // 竖列表：过滤全部预约根（补充下次仅瀑布）
      final listRows = [
        for (final r in rows)
          if (!catalogRootIsAppointment(r.eventId, catalog)) r,
      ];
      return wrapCardsRefresh(
        ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, cardsBottomPad),
          itemCount: listRows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final row = listRows[i];
            final activeTiming = useDemoSkeleton
                ? null
                : findLatestActiveTimingForRoot(
                    items: historyItems,
                    rootEventId: row.eventId,
                    catalog: catalog,
                  );
            // logo/色跟胜出子 prediction；标题用根 row.eventName
            final brandId = row.prediction?.eventId ?? row.eventId;
            return _PredictionEventCard(
              row: row,
              definition: lookupEventById(catalog, brandId),
              logoAnchorKey: logoAnchors.keyFor(row.eventId),
              now: now,
              chartLoading: useDemoSkeleton ? false : chartsLoading,
              compact: false,
              heartbeat: false,
              chartPoints: useDemoSkeleton || activeTiming != null
                  ? const []
                  : row.chartPoints,
              // 该根近窗真历史，供准确率柱 / 小结
              accuracyRecords: accuracyByRoot[row.eventId] ?? const [],
              pastDaysBeforeToday: 6,
              showYAxis: !useDemoSkeleton && activeTiming == null,
              relativeText: activeTiming != null
                  ? null
                  : _relativeFor(row, now, grid: false),
              activeTiming: activeTiming,
              activeExpectEndAt: etaForActive(activeTiming, row.eventId),
              onToggle: useDemoSkeleton
                  ? null
                  : (v) {
                      unawaited(onForecastToggle(row.eventId, v));
                    },
              onCardTap: addEventTapFor(row, activeTiming: activeTiming),
              onLongPressLayout: onLongPressLayoutToggle,
              onEditLastOccurrence: editLastTapFor(row),
            );
          },
        ),
      );
    }

    // 登录 / 绑定门闸（横竖屏共用）；量身定做 Dialog 已退役。
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
                    // 横屏语音：flag 关闭时不挂 binder / 不 activate
                    if (kPredictionLandscapeVoiceEnabled)
                      LandscapeVoiceLifecycleBinder(
                        landscape: true,
                        surfaceVisible: predictionPageVisible,
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
          if (kPredictionLandscapeVoiceEnabled && landscapeVoice != null) ...[
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
                  child: LandscapeVoiceSubtitleToast(
                    text: landscapeVoice.subtitle,
                    isThinking: landscapeVoice.subtitleKind ==
                        LandscapeVoiceSubtitleKind.thinking,
                    breathe: landscapeVoice.subtitleKind ==
                            LandscapeVoiceSubtitleKind.thinking ||
                        landscapeVoice.subtitleKind ==
                            LandscapeVoiceSubtitleKind.status,
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
                          // 习惯上报：投屏确认；不 await，不堵锁横屏。
                          unawaited(
                            ref
                                .read(clientUsageReporterProvider)
                                .reportEvent(
                                  ClientUsageEvents.predictionLandscapeCast,
                                ),
                          );
                          unawaited(_lockPredictionLandscapeCast());
                        }
                      },
                      icon: const Icon(Icons.cast),
                    ),

                    IconButton(
                      onPressed: () {
                        final cur = layout;
                        final next = cur == PredictionCardsLayout.grid
                            ? PredictionCardsLayout.list
                            : PredictionCardsLayout.grid;
                        unawaited(
                          ref
                              .read(predictionCardsLayoutProvider.notifier)
                              .setLayout(next)
                              .then((_) {
                            return ref
                                .read(clientUsageReporterProvider)
                                .reportEvent(
                                  next == PredictionCardsLayout.list
                                      ? ClientUsageEvents
                                          .predictionLayoutToList()
                                      : ClientUsageEvents
                                          .predictionLayoutToGrid(),
                                );
                          }),
                        );
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
                          // 通知未授权引导（仅竖屏；横屏不渲染）。
                          if (showNotifOptInBanner)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _NotificationOptInBanner(
                                onShell: onShell,
                                accent: Theme.of(context).colorScheme.primary,
                                needsSettings: notifAuth ==
                                    OsNotificationAuth.permanentlyDenied,
                                onEnable: () async {
                                  final ok = await ref
                                      .read(osNotificationAuthProvider.notifier)
                                      .requestOrOpenSettings();
                                  if (ok) {
                                    await syncAppPushRegistration(ref);
                                  }
                                },
                                onDismiss: () {
                                  ref
                                      .read(
                                        notificationOptInBannerDismissedProvider
                                            .notifier,
                                      )
                                      .state = true;
                                },
                              ),
                            ),
                          // Auth 冷态不展示接下来3小时；已绑定态空窗也常显（保 AI分析入口）。
                          if (!authGuestChrome)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _NextThreeHoursTimeline(
                                body: timelineText ??
                                    kNextThreeHoursEmptyBodyCopy,
                                onOpenFeeding: () {
                                  ref
                                      .read(homePagerRequestProvider.notifier)
                                      .requestPage(HomePagerPage.feeding);
                                },
                                onOpenAiAnalysis: () {
                                  context.push('/prediction/ai-analysis');
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

          // 竖屏语音/小组件球已上移 UcgHomeShell；本页仅保留广场贴边球
          // 竖屏广场入口贴边球（资格开通后）
          if (showUcgSquareBall)
            Positioned.fill(
              child: UcgSquareEdgeDock(
                bottomReserve: voiceBottom,
                onPointerOccupied: (occupied) {
                  ref.read(homePagerScrollBlockedProvider.notifier).state =
                      occupied;
                },
              ),
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
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // 横屏略放宽可用高度，并减小上下留白。
    final factor = landscape ? 0.88 : 0.55;
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
                    child: child,
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
/// 预测页竖屏：系统通知未开时的引导横条（会话可关）。
class _NotificationOptInBanner extends StatelessWidget {
  const _NotificationOptInBanner({
    required this.onShell,
    required this.accent,
    required this.needsSettings,
    required this.onEnable,
    required this.onDismiss,
  });

  final Color onShell;
  final Color accent;
  final bool needsSettings;
  final Future<void> Function() onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_active_outlined, size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '开启消息通知后，事件快到时会提醒你，不用一直盯着手机，也不容易忘记录。',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: onShell.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => unawaited(onEnable()),
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        needsSettings ? '去系统设置开启' : '去开启',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '本次先不提醒',
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                size: 18,
                color: onShell.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// 三小时窗无事项时的正文（卡常显，保 AI分析入口）。
const kNextThreeHoursEmptyBodyCopy = '接下来 3 小时暂无事项，享受属于自己的时光吧。';

/// 「接下来3小时」：全量正文；主区点进喂养；右侧「AI分析」进分析页。
class _NextThreeHoursTimeline extends StatelessWidget {
  const _NextThreeHoursTimeline({
    required this.body,
    required this.onOpenFeeding,
    required this.onOpenAiAnalysis,
  });

  final String body;
  final VoidCallback onOpenFeeding;
  final VoidCallback onOpenAiAnalysis;

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
        onTap: onOpenFeeding,
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
                    // 独立控件：只进 AI 分析，不导航喂养
                    Material(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onOpenAiAnalysis,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            'AI分析',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: bodyStyle),
              ],
            ),
          ),
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
    this.physics,
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
  final ScrollPhysics? physics;

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
      physics: physics,
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
    // 矮屏时竖排提示易撑破 Column；Flexible+FittedBox 可收缩，轨仍占主高
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
        Flexible(
          fit: FlexFit.loose,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: _landscapeVerticalCharColumn('拖动调整大小', hintStyle),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 2,
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
    this.accuracyRecords = const [],
    this.titleInlineLogo = false,
    this.activeTiming,
    this.activeExpectEndAt,
    this.landscapeMetrics,
    this.onToggle,
    this.onCardTap,
    this.onLongPressLayout,
    this.onEditLastOccurrence,
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

  /// 该卡事件根真历史（竖列表准确率柱 / 小结）；瀑布不传。
  final List<HistoryRecord> accuracyRecords;
  final int pastDaysBeforeToday;
  final bool showYAxis;
  final String? relativeText;

  /// 手机横屏非首行：标题旁小 logo，隐藏倒计时上方大图。
  final bool titleInlineLogo;

  /// 进行中计时：非 null 时走 active chrome（列表与网格均支持）。
  final HistoryRecord? activeTiming;

  /// 进行中预计结束（duration 有把握时）；无则不展示 ETA 行。
  final DateTime? activeExpectEndAt;

  /// 横屏 compact：按列宽 scale 的尺寸表；竖屏 grid 为 null。
  final PredictionLandscapeCardMetrics? landscapeMetrics;

  /// null 时禁用推演开关（冷态骨架）。
  final ValueChanged<bool>? onToggle;

  /// 仅网格态：整卡加事件；冷态引导登录/绑定。
  final VoidCallback? onCardTap;

  /// 竖屏热态整卡长按切换布局；横屏 / 骨架为 null。
  final VoidCallback? onLongPressLayout;

  /// 「上一次」文案：打开喂养同款编辑 Sheet；null 表示不可点。
  final VoidCallback? onEditLastOccurrence;

  @override
  ConsumerState<_PredictionEventCard> createState() =>
      _PredictionEventCardState();
}

class _PredictionEventCardState extends ConsumerState<_PredictionEventCard> {
  var _stopping = false;
  var _recallBusy = false;
  var _appointmentBusy = false;

  /// 预约卡：补充/编辑下次触发时间（专用 sheet，无清空）。
  Future<void> _onSupplementAppointment({
    required EventDefinition? definition,
  }) async {
    if (_appointmentBusy) return;
    final catalog = ref.read(eventCatalogProvider).items;
    final rootId = widget.row.eventId.trim();
    if (rootId.isEmpty) return;
    final def = definition ?? lookupEventById(catalog, rootId);
    if (def == null) return;
    setState(() => _appointmentBusy = true);
    try {
      // 拉取 nextAt+remark，改约默认回填上次预约备注
      final value = await ensureAppointmentNext(ref, rootId);
      if (!mounted) return;
      await showAppointmentNextSheetAndSave(
        context,
        ref: ref,
        rootEventId: rootId,
        displayEvent: def,
        initialNextAt: appointmentNextAtFromSec(value.nextAtSec),
        initialRemark: value.remark,
      );
    } finally {
      if (mounted) setState(() => _appointmentBusy = false);
    }
  }

  /// countdown 块：预约可点改约（吸收手势，不冒泡到整卡 add）。
  /// 倒计时正上方的「预计约…」；无文案不占位。
  Widget? _buildExpectAboveCountdownLine({
    required String? expectLabel,
    required double captionFontSize,
    required Color accent,
  }) {
    if (expectLabel == null) return null;
    return Text(
      expectLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: captionFontSize,
        color: accent.withValues(alpha: 0.85),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// 钟点把握不足软标；无则不占位。
  Widget? _buildTodConfidenceLowLine({
    required bool show,
    required double captionFontSize,
    required Color accent,
  }) {
    if (!show) return null;
    return Text(
      '此刻把握不足',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: captionFontSize,
        color: accent.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// 时刻态：约 caption 级，不放大；日期前缀略小于 HH:mm。
  Widget _buildEstimatedClockDigits({
    required PredictionEstimatedClockParts parts,
    required double captionFontSize,
    required Color accent,
  }) {
    // 时刻点不用倒计时大号；略高于说明字以保可扫读
    final hmSize = captionFontSize + 4;
    final hmStyle = TextStyle(
      fontSize: hmSize,
      fontWeight: FontWeight.w600,
      color: accent,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.5,
    );
    final prefix = parts.datePrefix;
    if (prefix == null || prefix.isEmpty) {
      return Text(parts.hm, style: hmStyle);
    }
    final dateStyle = TextStyle(
      fontSize: captionFontSize,
      fontWeight: FontWeight.w500,
      color: accent.withValues(alpha: 0.85),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(prefix, style: dateStyle),
        const SizedBox(width: 6),
        Text(parts.hm, style: hmStyle),
      ],
    );
  }

  Widget _buildAppointmentAwareCountdown({
    required bool isAppointment,
    required String titleName,
    required String countdown,
    required double captionFontSize,
    required double countdownFontSize,
    required double sectionGapSm,
    required Color accent,
    required EventDefinition? definition,
    String? expectLabel,
    bool todConfidenceLow = false,
    /// 逾期或剩余 &gt;10m：只显示预估时刻。
    bool showEstimatedClock = false,
    PredictionEstimatedClockParts? clockParts,
    /// 下次预约备注（非空时追加在标题后）。
    String nextRemark = '',
  }) {
    // 预约根不展示钟点软标
    final showSoft = !isAppointment && todConfidenceLow;
    // 时刻态：软标并入标题「此刻把握不足 · 预计…时刻」；倒计时态仍独占一行
    final softInlineInCaption = showSoft && showEstimatedClock;
    final softLine = _buildTodConfidenceLowLine(
      show: showSoft && !softInlineInCaption,
      captionFontSize: captionFontSize,
      accent: accent,
    );
    final expectLine = _buildExpectAboveCountdownLine(
      expectLabel: expectLabel,
      captionFontSize: captionFontSize,
      accent: accent,
    );
    // 预约用「预约」语义；非预约保持「预计/倒计时」
    final baseCaption = showEstimatedClock
        ? (isAppointment ? '预约$titleName时刻' : '预计$titleName时刻')
        : (isAppointment
            ? '距离下次$titleName预约'
            : '距离下次$titleName倒计时');
    // 下次预约备注：非空原样追加（不 Trim 内容，空串不展示）
    final withRemark = (isAppointment && nextRemark.isNotEmpty)
        ? '$baseCaption · $nextRemark'
        : baseCaption;
    final countdownCaption =
        softInlineInCaption ? '此刻把握不足 · $withRemark' : withRemark;
    // 倒计时保持大号；时刻态走 caption 级（不放大）
    final digits = showEstimatedClock && clockParts != null
        ? _buildEstimatedClockDigits(
            parts: clockParts,
            captionFontSize: captionFontSize,
            accent: accent,
          )
        : Text(
            countdown,
            style: TextStyle(
              fontSize: countdownFontSize,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          );
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (softLine != null) ...[
          softLine,
          SizedBox(height: sectionGapSm),
        ],
        if (expectLine != null) ...[
          expectLine,
          SizedBox(height: sectionGapSm),
        ],
        Text(
          countdownCaption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
            child: digits,
          ),
        ),
      ],
    );
    if (!isAppointment) return block;
    // GestureDetector 吸收命中，避免冒泡到整卡 InkWell 加喂养
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _appointmentBusy
          ? null
          : () => unawaited(
                _onSupplementAppointment(definition: definition),
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: block,
      ),
    );
  }

  /// 热态单事件样本不足：仅间隔 Sheet 写回忆种子（不写喂养历史）；确认后同层思考。
  Future<void> _onPickIntervalRecall({
    required EventDefinition? definition,
    required String eventName,
  }) async {
    final row = widget.row;
    final lastAt = row.lastAt;
    if (lastAt == null || _recallBusy) return;
    setState(() => _recallBusy = true);
    try {
      final minutes = await pickRecallIntervalMinutes(
        context,
        definition: definition,
        eventName: eventName,
        lastAt: lastAt,
        onCommit: (mins) async {
          final interval = Duration(minutes: mins);
          if (interval < kMinIntervalForPrediction) {
            showAppToast('间隔至少 15 分钟', tone: AppToastTone.error);
            return false;
          }
          final seed = PredictionRecallSeed(
            rootEventId: row.eventId,
            leafEventId: row.eventId,
            lastAt: lastAt,
            interval: interval,
            occurrenceAts:
                synthesizeOccurrenceAts(lastAt: lastAt, interval: interval),
          );
          await ref.read(predictionRecallSeedsProvider.notifier).upsertSeed(seed);
          // 走父级 onToggle 闸（满额弹框）；无开关时不强制开启。
          widget.onToggle?.call(true);
          return true;
        },
      );
      if (!mounted || minutes == null) return;
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
    // 竖列表有准确率图区：纯对照卡（仅名+logo+开关+图）
    final accuracyOnlyChrome = !compact && enabled && pred != null;
    // 计时中仅网格：名旁小 logo + elapsed + 停止
    // 列表与网格均展示进行中 chrome + 可选 ETA（对照卡除外）
    final showActiveTiming = widget.activeTiming != null;
    final activeEtaLabel = (showActiveTiming &&
            widget.activeExpectEndAt != null)
        ? formatActiveTimingEtaLabel(widget.activeExpectEndAt!, now)
        : null;
    // 计时中热态：叶子图/名/色；对照卡：强制根 logo/色；其它热态：父层 definition（可胜出子）
    final catalog = ref.watch(eventCatalogProvider).items;
    final rootDef = lookupEventById(catalog, row.eventId);
    final leafDef = showActiveTiming
        ? lookupEventForRecord(catalog, widget.activeTiming!)
        : null;
    final useTimingTitle = showActiveTiming && !accuracyOnlyChrome;
    // 对照卡 logo 跟根；计时中跟叶子；瀑布流等跟父层 brandId（胜出子）
    final titleDef = accuracyOnlyChrome
        ? (rootDef ?? definition)
        : (useTimingTitle ? (leafDef ?? definition) : definition);
    final titleName = useTimingTitle
        ? ((leafDef?.name.trim().isNotEmpty ?? false)
            ? leafDef!.name.trim()
            : (widget.activeTiming!.eventName.trim().isNotEmpty
                ? widget.activeTiming!.eventName.trim()
                : row.eventName))
        : row.eventName;
    // 对照卡 accent 跟根色（勿读可能为子色的 row.colorHex）；计时中跟叶子；热态读 row.colorHex（可胜出子）
    final accent = accuracyOnlyChrome
        ? resolveEventColor(context, rootDef)
        : (useTimingTitle
            ? (leafDef != null
                ? resolveEventColor(context, leafDef)
                : _rootAccent(context))
            : _rootAccent(context));
    // 列表 / 计时中 / 手机横屏后列：标题旁小 logo；首列瀑布流仍用倒计时上方大图
    final m = widget.landscapeMetrics;
    final titleLogoSize = m?.titleLogoSize ?? 28.0;
    final heroLogoSize = m?.heroLogoSize ?? 52.0;
    // 对照卡需给标题留高
    final chartH = accuracyOnlyChrome ? 112.0 : 96.0;
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
    // 预约根：开关文案用「预约」
    final isAppointment =
        catalogRootIsAppointment(widget.row.eventId, catalog);
    final toggleCaption = isAppointment
        ? '${enabled ? "关闭" : "开启"}$titleName预约'
        : '${enabled ? "关闭" : "开启"}$titleName预测';
    final overdue = pred != null && pred.isOverdue(now);
    // 上一次：行内已优先 latest-by-event（预约用根 id；不读 appointment_next）
    final displayLastAt = row.lastAt;
    final displayLastRemark = row.lastRemark;
    // 热态卡有 lastAt 才展示「上一次」行；对照卡隐藏。
    // 「补充上一次」仍由 showAddLastOccurrence 在 lastAt==null 时给出。
    final showLastOccurrence = !accuracyOnlyChrome &&
        !showActiveTiming &&
        widget.onToggle != null &&
        displayLastAt != null;
    // 上次发生：前缀跟同桶 lastLabel（有 pred 为胜出子名）；预约省前缀
    final lastLabelName = row.lastLabelEventName.trim().isNotEmpty
        ? row.lastLabelEventName.trim()
        : titleName;
    final lastOccurrenceLabel = showLastOccurrence
        ? formatPredictionLastOccurrenceLabel(
            lastLabelName,
            displayLastAt,
            now,
            remark: displayLastRemark,
            includeEventNamePrefix: !isAppointment,
          )
        : null;
    // 下次预约备注（缓存）
    final nextAppointmentRemark = isAppointment
        ? (ref.watch(appointmentNextCacheProvider)[row.eventId]?.remark ?? '')
        : '';
    // 卡上 expect：duration（下次用时）永不展示；amount（下次用量）仅倒计时超时展示。
    // 计时中预计结束走 activeEtaLabel，不经此门闩。横屏紧凑省略叶子名。
    String? expectLabel;
    if (!accuracyOnlyChrome &&
        pred != null &&
        !showActiveTiming &&
        pred.hasExpect) {
      final kind = pred.expectKind?.trim();
      if (kind == kExpectKindAmount && overdue) {
        expectLabel = formatPredictionExpectCardLabel(
          pred,
          includeLeaf: widget.landscapeMetrics == null,
        );
      }
    }
    // 时刻态：逾期或剩余 >10m；否则 H:MM:SS
    final showEstimatedClock = pred != null &&
        !showActiveTiming &&
        predictionShowsEstimatedClock(
          pred.nextAt,
          now,
          overdue: overdue,
        );
    final clockParts = (pred != null && showEstimatedClock)
        ? predictionEstimatedClockParts(pred.nextAt, now)
        : null;
    final countdown = (pred == null || showActiveTiming)
        ? null
        : formatPredictionCountdownHms(pred.nextAt, now, overdue: overdue);
    final activeElapsed = showActiveTiming
        ? formatActiveTimerElapsed(
            now.difference(activeTimingStartAt(widget.activeTiming!)),
          )
        : null;
    // 大 logo：仅普通 compact 且非后列侧 logo；预约卡固定标题侧 logo
    final showHeroLogo = compact &&
        !isAppointment &&
        !showActiveTiming &&
        !widget.titleInlineLogo &&
        enabled &&
        pred != null &&
        countdown != null;
    // 补齐 CTA 由入参派生（热态 onToggle!=null）；关推演 / 计时中 / 已有 pred 皆无
    final hotCard = widget.onToggle != null;
    final showAddLastOccurrence = !accuracyOnlyChrome &&
        enabled &&
        !showActiveTiming &&
        pred == null &&
        row.lastAt == null &&
        hotCard &&
        widget.onCardTap != null;
    // 预约：无预测时「补充下次」；非预约：有 lastAt 时「补充大概多久一次」
    final showAppointmentNext = !accuracyOnlyChrome &&
        enabled &&
        !showActiveTiming &&
        pred == null &&
        hotCard &&
        isAppointment;
    final showIntervalRecall = !accuracyOnlyChrome &&
        enabled &&
        !showActiveTiming &&
        pred == null &&
        row.lastAt != null &&
        hotCard &&
        !isAppointment;
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
              // 对照卡不展示 relative / 开关旁说明
              if (!accuracyOnlyChrome)
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
                  child: widget.onEditLastOccurrence == null
                      ? Text(
                          lastOccurrenceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: captionFontSize,
                            color: accent,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onEditLastOccurrence,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                lastOccurrenceLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: captionFontSize,
                                  color: accent,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                  decorationColor: accent.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
              // expect 改挂倒计时区块上方，标题区不再占位
              if (showAddLastOccurrence) ...[
                SizedBox(height: sectionGapMd),
                _HeartbeatAccentButton(
                  accent: accent,
                  busy: false,
                  label: '补充上一次',
                  onPressed: widget.onCardTap!,
                ),
              ],
              if (showAppointmentNext) ...[
                SizedBox(height: sectionGapMd),
                _HeartbeatAccentButton(
                  accent: accent,
                  busy: _appointmentBusy,
                  label: '补充下次',
                  onPressed: () => unawaited(_onSupplementAppointment(
                    definition: titleDef ?? definition,
                  )),
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
          // 对照卡隐藏计时中整块（含停止）
          if (!accuracyOnlyChrome &&
              showActiveTiming &&
              activeElapsed != null) ...[
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
            // 有 duration 把握才占位；超时保留原时刻 +「已超时」
            if (activeEtaLabel != null) ...[
              SizedBox(height: sectionGapSm),
              Center(
                child: Text(
                  activeEtaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: captionFontSize,
                    color: accent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
            SizedBox(height: sectionGapMd),
            // 停止独立命中 + 可点时心跳
            _HeartbeatStopButton(
              accent: accent,
              busy: _stopping,
              onPressed: () => unawaited(_onStop(widget.activeTiming!)),
            ),
          ] else ...[
            // 竖屏 compact：倒计时；预约根可点改约
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
              _buildAppointmentAwareCountdown(
                isAppointment: isAppointment,
                titleName: titleName,
                countdown: countdown,
                captionFontSize: captionFontSize,
                countdownFontSize: countdownFontSize,
                sectionGapSm: sectionGapSm,
                accent: accent,
                definition: titleDef ?? definition,
                // 有大 logo 时位于 logo 与倒计时之间；无大 logo 仍贴倒计时
                expectLabel: expectLabel,
                todConfidenceLow: pred.todConfidenceLow,
                showEstimatedClock: showEstimatedClock,
                clockParts: clockParts,
                nextRemark: nextAppointmentRemark,
              ),
            ],
            // 非对照卡：预约竖卡可改约 countdown；对照卡只留准确率图
            if (!accuracyOnlyChrome &&
                enabled &&
                pred != null &&
                !compact &&
                isAppointment &&
                countdown != null) ...[
              const SizedBox(height: 8),
              _buildAppointmentAwareCountdown(
                isAppointment: true,
                titleName: titleName,
                countdown: countdown,
                captionFontSize: captionFontSize,
                countdownFontSize: countdownFontSize,
                sectionGapSm: sectionGapSm,
                accent: accent,
                definition: titleDef ?? definition,
                expectLabel: expectLabel,
                showEstimatedClock: showEstimatedClock,
                clockParts: clockParts,
                nextRemark: nextAppointmentRemark,
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
                    // 竖列表：准确率柱 / 示例柱 / 点柱小结
                    : _PredictAccuracyChartPane(
                        eventId: widget.row.eventId,
                        records: widget.accuracyRecords,
                        catalog: catalog,
                        now: now,
                        accent: accent,
                        pastDaysBeforeToday: widget.pastDaysBeforeToday,
                        // 对照卡示例柱 oneShot 跟根类型（与根聚合准确率一致）
                        oneShot: (rootDef ?? definition)?.parsedEventType ==
                            EventCatalogEventType.one,
                        onLongPressLayout: widget.onLongPressLayout,
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
          child: widget.onCardTap == null && widget.onLongPressLayout == null
              ? content
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onCardTap,
                    onLongPress: widget.onLongPressLayout,
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 竖列表卡图区：近 N 日准确率柱 ↔ 点柱后当日预测小结（无真样本时示例柱）。
class _PredictAccuracyChartPane extends StatefulWidget {
  const _PredictAccuracyChartPane({
    required this.eventId,
    required this.records,
    required this.catalog,
    required this.now,
    required this.accent,
    required this.pastDaysBeforeToday,
    this.oneShot = false,
    this.onLongPressLayout,
  });

  final String eventId;
  final List<HistoryRecord> records;
  final List<EventDefinition> catalog;
  final DateTime now;
  final Color accent;
  final int pastDaysBeforeToday;

  /// 一次性事件：示例细节不含量段
  final bool oneShot;

  /// 显式长按切 list↔瀑布（与整卡同回调）
  final VoidCallback? onLongPressLayout;

  @override
  State<_PredictAccuracyChartPane> createState() =>
      _PredictAccuracyChartPaneState();
}

class _PredictAccuracyChartPaneState extends State<_PredictAccuracyChartPane> {
  /// 非 null 时图区展示该日小结
  DateTime? _summaryDay;

  /// 当前小结是否来自示例柱（有真样本后须清掉）
  bool _summaryIsSample = false;

  /// Down 时缓存柱索引（TapUp 时 spot 可能已空）
  int? _pendingBarIndex;

  static String _xAxisDayLabel(DateTime day, DateTime today) =>
      formatRelativeCalendarDay(predictAccuracyDayKey(day), today);

  static String _fmtHm(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// 合成分 → 绿/黄/红
  static Color _trafficColor(PredictAccuracyTraffic t) {
    switch (t) {
      case PredictAccuracyTraffic.green:
        return const Color(0xFF2CB771);
      case PredictAccuracyTraffic.yellow:
        return const Color(0xFFE6A23C);
      case PredictAccuracyTraffic.red:
        return const Color(0xFFE45B5B);
    }
  }

  /// 细节行：预计 HH:mm[ · 量] → 实际 HH:mm[ · 量]
  static String _detailLine(PredictAccuracySample s) {
    final eq = s.expectQtyLabel;
    final aq = s.actualQtyLabel;
    final left = (eq != null && eq.isNotEmpty)
        ? '预计 ${_fmtHm(s.expectAt)} · $eq'
        : '预计 ${_fmtHm(s.expectAt)}';
    final right = (aq != null && aq.isNotEmpty)
        ? '实际 ${_fmtHm(s.actualAt)} · $aq'
        : '实际 ${_fmtHm(s.actualAt)}';
    return '$left → $right';
  }

  @override
  Widget build(BuildContext context) {
    final days = predictAccuracyWindowDays(
      now: widget.now,
      pastDaysBeforeToday: widget.pastDaysBeforeToday,
    );
    final realSamples = predictAccuracySamplesFromHistory(
      widget.records,
      catalog: widget.catalog,
    );
    final realPercents =
        predictDailyAccuracyPercents(days: days, samples: realSamples);
    final hasAny = realPercents.any((e) => e != null);

    // 真样本到达后退出示例小结，避免假数据残留
    if (hasAny && _summaryIsSample) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_summaryIsSample) return;
        setState(() {
          _summaryDay = null;
          _summaryIsSample = false;
        });
      });
    }

    // 阻断冒泡到整卡 InkWell；小结整区单击回柱图；显式长按切布局
    return GestureDetector(
      onTap: _summaryDay == null
          ? () {}
          : () => setState(() {
                _summaryDay = null;
                _summaryIsSample = false;
              }),
      onLongPress: widget.onLongPressLayout,
      behavior: HitTestBehavior.opaque,
      child: _summaryDay == null
          ? _buildBars(
              context,
              days: days,
              realPercents: realPercents,
              hasAny: hasAny,
            )
          : _buildSummary(context, isSample: _summaryIsSample && !hasAny),
    );
  }

  Widget _chartTitle({required bool isSample}) {
    final accent = widget.accent;
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: accent,
    );
    if (!isSample) {
      return Text(
        '预测准确率分布图',
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: const [
          TextSpan(text: '预测准确率分布图'),
          TextSpan(text: ' · '),
          TextSpan(text: '示例数据'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBars(
    BuildContext context, {
    required List<DateTime> days,
    required List<int?> realPercents,
    required bool hasAny,
  }) {
    final muted = AppColor.textOnPanelGlassMuted(context);
    final today = predictAccuracyDayKey(widget.now);

    // 无真对照：示例柱（不写 history）
    if (!hasAny) {
      final samplePct = predictAccuracySamplePercents(
        eventId: widget.eventId,
        dayCount: days.length,
      );
      final percents = <int?>[for (final p in samplePct) p];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _chartTitle(isSample: true),
          const SizedBox(height: 2),
          Expanded(
            child: _accuracyBarChart(
              context,
              days: days,
              percents: percents,
              today: today,
              muted: muted,
              isSample: true,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chartTitle(isSample: false),
        const SizedBox(height: 2),
        Expanded(
          child: _accuracyBarChart(
            context,
            days: days,
            percents: realPercents,
            today: today,
            muted: muted,
            isSample: false,
          ),
        ),
      ],
    );
  }

  /// 共用柱图（真 / 示例）；示例日全部可点。
  Widget _accuracyBarChart(
    BuildContext context, {
    required List<DateTime> days,
    required List<int?> percents,
    required DateTime today,
    required Color muted,
    required bool isSample,
  }) {
    final accent = widget.accent;
    final topHighlight = Color.lerp(accent, Colors.white, 0.35) ?? accent;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 4,
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  // 真路径无样本日高度 0 + 透明；示例日必有 %
                  toY: (percents[i] ?? 0).toDouble(),
                  width: days.length > 8 ? 8 : 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  color: percents[i] == null ? Colors.transparent : null,
                  gradient: percents[i] == null
                      ? null
                      : LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            accent.withValues(alpha: 0.45),
                            accent.withValues(alpha: 0.9),
                            topHighlight.withValues(alpha: 0.95),
                          ],
                        ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= percents.length) {
                  return const SizedBox.shrink();
                }
                final pct = percents[i];
                if (pct == null) return const SizedBox.shrink();
                final alpha = pct >= 70 ? 0.95 : 0.62;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: accent.withValues(alpha: alpha),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= days.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _xAxisDayLabel(days[i], today),
                  style: TextStyle(fontSize: 9, color: muted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            final group = response?.spot?.touchedBarGroup;
            if (group != null) _pendingBarIndex = group.x;
            if (event is FlTapUpEvent || event is FlPanEndEvent) {
              final i = _pendingBarIndex;
              _pendingBarIndex = null;
              if (i == null || i < 0 || i >= days.length) return;
              // 真路径空日不进小结；示例全日可进
              if (percents[i] == null) return;
              setState(() {
                _summaryDay = days[i];
                _summaryIsSample = isSample;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, {required bool isSample}) {
    final day = _summaryDay!;
    final samples = isSample
        ? predictAccuracySampleRowsForDay(
            eventId: widget.eventId,
            day: day,
            oneShot: widget.oneShot,
          )
        : predictAccuracySamplesForDay(
            samples: predictAccuracySamplesFromHistory(
              widget.records,
              catalog: widget.catalog,
            ),
            day: day,
          );
    final muted = AppColor.textOnPanelGlassMuted(context);
    final today = predictAccuracyDayKey(widget.now);
    final dayLabel = _xAxisDayLabel(day, today);
    final title =
        isSample ? '$dayLabel · 预测小结 · 示例' : '$dayLabel · 预测小结';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左箭头返回柱图（不用「近7日」）；标题随事件色
        Row(
          children: [
            InkWell(
              onTap: () => setState(() {
                _summaryDay = null;
                _summaryIsSample = false;
              }),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: widget.accent,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.accent,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: samples.isEmpty
              ? Center(
                  child: Text(
                    '该日暂无对照',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: samples.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final s = samples[i];
                    return Text(
                      _detailLine(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _trafficColor(s.traffic),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
