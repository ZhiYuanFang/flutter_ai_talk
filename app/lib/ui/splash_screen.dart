import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories.dart';
import '../providers/device_no_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../theme/app_theme_scope.dart';
import 'version_prompt.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await ref.read(sessionProvider).restore();
    if (!mounted) return;
    if (ref.read(sessionProvider).isLoggedIn) {
      await ref.read(deviceNoNotifierProvider.notifier).refresh();
      await ref.read(signInChannelProvider.notifier).restoreFromPrefs();
    } else {
      await ref.read(signInChannelProvider.notifier).clear();
    }
    if (!mounted) return;
    final currentVersion = await readPackageVersion();
    if (!mounted) return;
    await maybeShowVersionPrompt(
      context: context,
      repo: ref.read(versionRepositoryProvider),
      currentVersion: currentVersion,
    );
    if (!mounted) return;
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    if (loggedIn) {
      final baby = await ref.read(settingsRepositoryProvider).loadBaby();
      ref.read(babySexProvider.notifier).state = baby.sex;
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
