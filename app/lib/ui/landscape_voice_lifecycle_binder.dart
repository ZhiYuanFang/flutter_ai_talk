import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/landscape_voice_provider.dart';
import '../router/app_route_observer.dart';

/// 绑定预测语音 activate/deactivate；竖屏额外认主壳 [ModalRoute.isCurrent]。
class LandscapeVoiceLifecycleBinder extends ConsumerStatefulWidget {
  const LandscapeVoiceLifecycleBinder({
    super.key,
    required this.landscape,
    required this.surfaceVisible,
  });

  /// true=横屏 flag；false=竖屏 flag。
  final bool landscape;

  /// 业务表面是否应激活（横屏=预测页可见；竖屏=非 UCG 未合格等）。
  final bool surfaceVisible;

  @override
  ConsumerState<LandscapeVoiceLifecycleBinder> createState() =>
      _LandscapeVoiceLifecycleBinderState();
}

class _LandscapeVoiceLifecycleBinderState
    extends ConsumerState<LandscapeVoiceLifecycleBinder> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant LandscapeVoiceLifecycleBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landscape != widget.landscape ||
        oldWidget.surfaceVisible != widget.surfaceVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void didPushNext() {
    // 被上层路由盖住。
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didPopNext() {
    // 上层路由弹出，主壳回到前台。
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    // 不在此 deactivate：Notifier 可能已 dispose；由 sync 在条件变化时处理。
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    // 竖屏：须主壳为当前路由；横屏仍只认业务 surface（预测页可见）。
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    final surface = widget.landscape
        ? widget.surfaceVisible
        : (widget.surfaceVisible && routeCurrent);
    syncLandscapeVoiceLifecycle(
      ref,
      context: context,
      landscape: widget.landscape,
      surfaceVisible: surface,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
