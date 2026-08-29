import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_pager.dart';
import '../providers/session_provider.dart';
import '../config/env.dart';
import 'focus_cleanup_observer.dart';
import '../ucg/ui/ucg_home_shell.dart';
import '../ucg/data/ucg_feature_flags.dart';
import '../ui/wechat_oauth_callback_screen.dart';
import '../ui/dev/ios_login_http_probe_screen.dart';
import '../ui/login_screen.dart';
import '../ui/register_screen.dart';
import '../ui/policy_screen.dart';
import '../ui/baby_bind_screen.dart';
import '../ui/baby_profile_edit_screen.dart';
import '../ui/change_password_screen.dart';
import '../ui/feedback_list_screen.dart';
import '../ui/settings_screen.dart';
import '../data/prediction_care_alert.dart';
import '../ui/pangbao_ai_screen.dart';
import '../ui/prediction_care_alert_screen.dart';
import '../ui/splash_screen.dart';
import '../ui/trends_screen.dart';
import '../ui/vip_purchase_screen.dart';
import '../ui/feature_unlock_hub_screen.dart';
import '../ui/home_widget_showcase_screen.dart';

/// 必须使用 [ref.read]，不能用 [ref.watch]：会话 [notifyListeners] 会触发重建，
/// 若此处 watch 会在 Splash 等异步流程中途销毁整个路由树，导致白屏与
/// “widget has been unmounted” 错误。
final goRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionProvider);
  final focusObserver = FocusCleanupNavigatorObserver();
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    observers: [focusObserver],
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'pangbao' &&
          (uri.host == 'home' || uri.path == '/home' || uri.path == '/')) {
        return '/home';
      }
      final loc = state.matchedLocation;
      if (loc == '/vip/purchase' && !kVipPurchaseEnabled) {
        return '/home';
      }
      final splash = loc == '/splash';
      final loggingIn = loc == '/login';
      final registering = loc == '/register';
      const settingsPathsRequiringLogin = <String>{
        '/settings/baby',
        '/settings/bind-baby',
        '/settings/change-password',
        '/settings/feedback',
        '/features/unlock',
        '/vip/purchase',
      };
      final guestAllowed = splash ||
          loggingIn ||
          registering ||
          loc.startsWith('/auth/') ||
          loc == '/policy' ||
          loc == '/home' ||
          loc == '/trends' ||
          loc == '/pangbao' ||
          loc == '/settings' ||
          loc == '/widgets/showcase';
      if (guestAllowed) {
        if (session.isLoggedIn && (loggingIn || registering)) {
          return AppEnv.postLoginRoute;
        }
        return null;
      }
      if (loc == '/dev/ios-login-http-probe') {
        if (!session.isLoggedIn) return '/login';
        return null;
      }
      if (!session.isLoggedIn && settingsPathsRequiringLogin.contains(loc)) {
        return '/login';
      }
      if (!session.isLoggedIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/wechat/callback',
        builder: (context, state) => const WeChatOAuthCallbackScreen(),
      ),
      GoRoute(
        path: '/dev/ios-login-http-probe',
        builder: (context, state) => const IosLoginHttpProbeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const UcgHomeShell(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsScreen(),
      ),
      GoRoute(
        // 深链兼容：旧 /pangbao 进主页并切到智能预测页
        path: '/pangbao',
        redirect: (context, state) {
          Future<void>.microtask(() {
            ref
                .read(homePagerRequestProvider.notifier)
                .requestPage(HomePagerPage.prediction);
          });
          return '/home';
        },
      ),
      GoRoute(
        // 预测页 tip 卡 push 进入陪伴（本阶段唯一产品入口）
        path: '/companion',
        builder: (context, state) =>
            const PangbaoAiScreen(embeddedInHomePager: false),
      ),
      GoRoute(
        // 护理留意详情：extra 传入 CareAlertEventItem
        path: '/prediction/alert',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is CareAlertEventItem) {
            return PredictionCareAlertScreen(item: extra);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('值得留意')),
            body: const Center(child: Text('暂无预警详情')),
          );
        },
      ),
      GoRoute(
        // VIP 购买：暂停闸门下 redirect；开启时需登录
        path: '/vip/purchase',
        redirect: (context, state) {
          if (!kVipPurchaseEnabled) return '/home';
          return null;
        },
        builder: (context, state) => const VipPurchaseScreen(),
      ),
      GoRoute(
        path: '/features/unlock',
        builder: (context, state) => const FeatureUnlockHubScreen(),
      ),
      GoRoute(
        path: '/widgets/showcase',
        builder: (context, state) => const HomeWidgetShowcaseScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/baby',
        builder: (context, state) => const BabyProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings/bind-baby',
        builder: (context, state) => const BabyBindScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/feedback',
        builder: (context, state) => const FeedbackListScreen(),
      ),
      GoRoute(
        path: '/policy',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'];
          return PolicyScreen(initialUrl: url);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('路由错误')),
      body: Center(child: Text(state.error?.message ?? '未知路径：${state.uri}')),
    ),
  );
});
