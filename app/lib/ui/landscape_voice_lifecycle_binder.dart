import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/landscape_voice_provider.dart';
import '../router/app_route_observer.dart';

/// 绑定预测语音 activate/deactivate。
///
/// 竖屏：仅当主壳被**其它 PageRoute** 覆盖时视为离开表面；
/// Overlay（sheet/dialog）会翻转 [ModalRoute.isCurrent]，但 **不得** 因此 teardown / 重载 KWS。
/// 横屏：仍只认业务 [surfaceVisible]（预测页可见）。
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
  /// 主壳 Page 之上是否压了另一 PageRoute（设置/登录等）。
  /// 依赖 [appRouteObserver] 为 `RouteObserver<PageRoute>`：Overlay 不得回调。
  var _coveredByPageRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
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
    // 上层 PageRoute 盖住主壳（非 Overlay）。
    _coveredByPageRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didPopNext() {
    // 上层 PageRoute 弹出，主壳回到 Page 级前台。
    _coveredByPageRoute = false;
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
    // 竖屏：Page 级覆盖才否；不得用 isCurrent（Overlay 也会 false → 误 teardown）。
    final surface = widget.landscape
        ? widget.surfaceVisible
        : (widget.surfaceVisible && !_coveredByPageRoute);
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
