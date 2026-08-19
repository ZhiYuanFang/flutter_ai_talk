import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/cold_start_background_sync.dart';
import 'bootstrap/cold_start_bootstrap.dart';
import 'bootstrap/ios_network_permission_probe.dart';
import 'platform/native_splash.dart';
import 'home_widget/home_widget_sync.dart';
import 'providers/event_catalog_notifier.dart';
import 'providers/home_history_notifier.dart';
import 'providers/prediction_range_history_provider.dart';
import 'providers/session_provider.dart';
import 'providers/sign_in_channel_provider.dart';
import 'api/ai_quota_errors.dart';
import 'providers/ai_quota_dialog_bus.dart';
import 'providers/toast_bus.dart';
import 'scaffold_messenger_key.dart';
import 'ui/widgets/app_toast.dart';
import 'ui/widgets/keyboard_input_bridge.dart';
import 'router/app_router.dart';
import 'theme/app_theme_schedule.dart';
import 'theme/app_theme_scope.dart';
import 'theme/custom_background_persist.dart';
import 'ui/widgets/keyboard_dismiss_scope.dart';
import 'ui/widgets/splash_logo_pulse.dart';

class PangbaoApp extends ConsumerStatefulWidget {
  const PangbaoApp({super.key});

  @override
  ConsumerState<PangbaoApp> createState() => _PangbaoAppState();
}

class _PangbaoAppState extends ConsumerState<PangbaoApp> with WidgetsBindingObserver {
  var _showStartupOverlay = true;
  var _startupStarted = false;
  Timer? _themeScheduleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeScheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshScheduledTheme(ref);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginStartupIfNeeded());
  }

  @override
  void dispose() {
    _themeScheduleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshScheduledTheme(ref);
      if (ref.read(sessionProvider).isLoggedIn) {
        unawaited(syncHomeWidgetFromRef(ref));
      }
    }
  }

  void _beginStartupIfNeeded() {
    if (_startupStarted) return;
    _startupStarted = true;
    unawaited(hideNativeSplash());
    unawaited(IosNetworkPermissionProbe.run());
    unawaited(_runColdStart());
  }

  Future<void> _runColdStart() async {
    final session = ref.read(sessionProvider);
    final result = await ColdStartBootstrap.run(session);
    if (!mounted) return;

    if (result.cachedSex != null) {
      ref.read(babySexProvider.notifier).state = result.cachedSex!;
    }
    await applyUserThemeBaseline(ref);

    if (ref.read(sessionProvider).isLoggedIn) {
      await ref.read(signInChannelProvider.notifier).restoreFromPrefs();
      await Future.wait<void>([
        ref.read(eventCatalogProvider.notifier).loadFromDisk(),
        ref.read(homeHistoryProvider.notifier).hydrateFromDiskForSplash(),
      ]);
      // 小组件/range ensure 改由 GatewayBootstrapGate（ColdStart 灌入 deviceNo 之后）执行，避免假空 ready。
    } else {
      await ref.read(signInChannelProvider.notifier).clear();
    }

    if (!mounted) return;
    ref.read(goRouterProvider).go(result.route);
    setState(() => _showStartupOverlay = false);
    // 已登录 bootstrap 由 HomeScreen GatewayBootstrapGate 单飞负责，避免与 gate 双跑占满 iOS 连接槽。
    if (!ref.read(sessionProvider).isLoggedIn) {
      unawaited(
        ColdStartBackgroundSync.run(
          ProviderScope.containerOf(context, listen: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppToastPayload?>(apiToastProvider, (previous, next) {
      if (next != null && next.message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAppToast(
            next.message,
            tone: next.tone,
            messenger: appScaffoldMessengerKey.currentState,
          );
          ref.read(apiToastProvider.notifier).state = null;
        });
      }
    });
    ref.listen<AiQuotaDialogRequest?>(aiQuotaDialogProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await handleAiQuotaBusinessCode(context, next.code);
        ref.read(aiQuotaDialogProvider.notifier).state = null;
      });
    });
    // ChangeNotifier 同一实例：须 select isLoggedIn，否则 notifyListeners 后 previous/next 同为已登录。
    ref.listen<bool>(
      sessionProvider.select((s) => s.isLoggedIn),
      (previous, isLoggedIn) {
        if (isLoggedIn) {
          unawaited(ensureWidgetReadyFromRef(ref));
        } else if (previous == true) {
          unawaited(onLogoutClearHomeWidget());
          ref.read(homeHistoryProvider.notifier).resetLoadMoreCircuit();
        }
      },
    );
    ref.listen<ThemePreferences>(effectiveThemeProvider, (previous, next) {
      unawaited(scheduleHomeWidgetSyncIfThemeChanged(ref, previous, next));
    });
    // range 就绪或 items 变更 → 推桌面预测（非 provider 构造自动 ensure）
    ref.listen<PredictionRangeHistoryState>(predictionRangeHistoryProvider,
        (prev, next) {
      if (!ref.read(sessionProvider).isLoggedIn) return;
      if (!next.ready || next.loading) return;
      final becameReady = prev == null || !prev.ready;
      final itemsChanged = prev != null &&
          prev.ready &&
          !listEquals(prev.items, next.items);
      if (becameReady || itemsChanged) {
        unawaited(scheduleHomeWidgetSync(ref));
      }
    });
    final router = ref.watch(goRouterProvider);
    final sex = ref.watch(babySexProvider);
    final effective = ref.watch(effectiveThemeProvider);
    final theme = buildAppTheme(
      sex: sex,
      customBackground: effective.seed,
      preset: effective.preset,
    );

    return MaterialApp.router(
      title: '胖宝',
      theme: theme,
      routerConfig: router,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      builder: (context, child) {
        return KeyboardDismissScope(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (child != null) KeyboardOverlayInsetSync(child: child),
              const KeyboardInputConfirmBarOverlay(),
              if (_showStartupOverlay) const StartupBrandingOverlay(),
            ],
          ),
        );
      },
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
