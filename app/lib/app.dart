import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/cold_start_bootstrap.dart';
import 'data/home_history_store.dart';
import 'platform/native_splash.dart';
import 'providers/device_no_notifier.dart';
import 'providers/event_catalog_notifier.dart';
import 'providers/home_history_notifier.dart';
import 'providers/session_provider.dart';
import 'providers/sign_in_channel_provider.dart';
import 'providers/toast_bus.dart';
import 'scaffold_messenger_key.dart';
import 'ui/widgets/app_toast.dart';
import 'router/app_router.dart';
import 'theme/app_theme_scope.dart';
import 'ui/widgets/keyboard_dismiss_scope.dart';
import 'ui/event_logo_startup_warmup.dart';
import 'ui/widgets/splash_logo_pulse.dart';

class PangbaoApp extends ConsumerStatefulWidget {
  const PangbaoApp({super.key});

  @override
  ConsumerState<PangbaoApp> createState() => _PangbaoAppState();
}

class _PangbaoAppState extends ConsumerState<PangbaoApp> {
  var _showStartupOverlay = true;
  var _startupStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginStartupIfNeeded());
  }

  void _beginStartupIfNeeded() {
    if (_startupStarted) return;
    _startupStarted = true;
    unawaited(hideNativeSplash());
    unawaited(_runColdStart());
  }

  Future<void> _runColdStart() async {
    final session = ref.read(sessionProvider);
    final result = await ColdStartBootstrap.run(session);
    if (!mounted) return;

    if (result.cachedSex != null) {
      ref.read(babySexProvider.notifier).state = result.cachedSex!;
    }
    if (result.cachedBg != null) {
      ref.read(customBackgroundProvider.notifier).state = result.cachedBg;
    }
    if (result.cachedPreset != null) {
      ref.read(themePresetProvider.notifier).state = result.cachedPreset;
    }

    if (ref.read(sessionProvider).isLoggedIn) {
      await Future.wait<void>([
        ref.read(deviceNoNotifierProvider.notifier).refresh(),
        ref.read(signInChannelProvider.notifier).restoreFromPrefs(),
      ]);
      HomeHistoryLog.d('coldStart bootstrap begin (before /home)');
      await ref.read(homeHistoryProvider.notifier).bootstrap();
      final h = ref.read(homeHistoryProvider);
      HomeHistoryLog.d(
        'coldStart history done items=${h.items.length} initialLoadDone=${h.initialLoadDone}',
      );
      await ref.read(eventCatalogProvider.notifier).bootstrap(maxAttempts: 3);
      HomeHistoryLog.d('coldStart catalog done');
      final warmupCtx = appScaffoldMessengerKey.currentContext;
      if (warmupCtx != null && warmupCtx.mounted) {
        await EventLogoStartupWarmup.precacheCatalog(
          warmupCtx,
          ref.read(eventCatalogProvider),
        );
      }
    } else {
      await ref.read(signInChannelProvider.notifier).clear();
    }

    if (!mounted) return;
    ref.read(goRouterProvider).go(result.route);
    setState(() => _showStartupOverlay = false);
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
    final router = ref.watch(goRouterProvider);
    final sex = ref.watch(babySexProvider);
    final customBg = ref.watch(customBackgroundProvider);
    final preset = ref.watch(themePresetProvider);
    final theme = buildAppTheme(sex: sex, customBackground: customBg, preset: preset);

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
              if (child != null) child,
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
