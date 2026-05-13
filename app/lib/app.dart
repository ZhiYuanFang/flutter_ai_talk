import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/toast_bus.dart';
import 'scaffold_messenger_key.dart';
import 'router/app_router.dart';
import 'theme/app_theme_scope.dart';
import 'theme/custom_background_persist.dart';

class PangbaoApp extends ConsumerStatefulWidget {
  const PangbaoApp({super.key});

  @override
  ConsumerState<PangbaoApp> createState() => _PangbaoAppState();
}

class _PangbaoAppState extends ConsumerState<PangbaoApp> {
  @override
  void initState() {
    super.initState();
    _restoreCustomBackground();
  }

  Future<void> _restoreCustomBackground() async {
    final color = await loadCustomBackground();
    if (!mounted || color == null) return;
    ref.read(customBackgroundProvider.notifier).state = color;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(apiToastProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          appScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(next)));
          ref.read(apiToastProvider.notifier).state = null;
        });
      }
    });
    final router = ref.watch(goRouterProvider);
    final sex = ref.watch(babySexProvider);
    final customBg = ref.watch(customBackgroundProvider);
    final theme = buildAppTheme(sex: sex, customBackground: customBg);

    return MaterialApp.router(
      title: '胖宝',
      theme: theme,
      routerConfig: router,
      scaffoldMessengerKey: appScaffoldMessengerKey,
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
