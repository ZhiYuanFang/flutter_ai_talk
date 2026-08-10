import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/edge_dock_geometry.dart';
import '../../data/edge_dock_occupancy.dart';
import '../../data/tip_models.dart';
import '../../providers/home_pager.dart';
import '../../providers/tip_provider.dart';
import '../startup_branding.dart';
import 'clinic_answer_body.dart';
import 'edge_dock_shell.dart';

const _kTipBadgeSize = 44.0;

/// 首页小贴士：展开卡（可滚/点进陪伴）+ 球态才可拖（EdgeDockShell）
class HomeTipPanel extends ConsumerStatefulWidget {
  const HomeTipPanel({super.key, this.onDraggingChanged});

  final ValueChanged<bool>? onDraggingChanged;

  @override
  ConsumerState<HomeTipPanel> createState() => _HomeTipPanelState();
}

class _HomeTipPanelState extends ConsumerState<HomeTipPanel>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _enterScale;
  late final AnimationController _collapseController;
  late final Animation<double> _collapseScale;
  late final Animation<double> _collapseFade;

  final _ballController = EdgeDockController();
  var _lastPlayedGeneration = -1;

  /// false=展开卡；true=EdgeDock 球（唯一可拖）
  var _ballMode = false;
  EdgeDockPlacement _ballPlacement = const EdgeDockPlacement.edge(
    kind: EdgeDockKind.edgePeek,
    edge: DockEdge.right,
    along: 0.35,
  );

  var _activePointers = 0;

  Size _estimateExpandedSize(Size viewport) {
    final maxW = viewport.width - 48;
    final maxH = viewport.height * 0.4;
    final h = (maxH + _kTipBadgeSize / 2).clamp(120.0, viewport.height);
    return Size(maxW.clamp(200.0, viewport.width), h);
  }

  void _openCompanionIfReady() {
    final tip = ref.read(tipProvider);
    if (!tip.canInjectToCompanion) return;
    ref
        .read(homePagerRequestProvider.notifier)
        .requestPage(HomePagerPage.prediction);
  }

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _enterScale = Tween<double>(begin: 0.62, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final collapseCurve = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInCubic,
    );
    _collapseScale = Tween<double>(begin: 1, end: 0.05).animate(collapseCurve);
    _collapseFade = Tween<double>(begin: 1, end: 0).animate(collapseCurve);
  }

  @override
  void dispose() {
    _enterController.dispose();
    _collapseController.dispose();
    _ballController.dispose();
    super.dispose();
  }

  void _setPageScrollBlocked(bool blocked) {
    widget.onDraggingChanged?.call(blocked);
  }

  void _onTipPointerDown(PointerDownEvent _) {
    _activePointers++;
    if (_activePointers == 1) _setPageScrollBlocked(true);
  }

  void _onTipPointerUpOrCancel(PointerEvent _) {
    if (_activePointers <= 0) return;
    _activePointers--;
    if (_activePointers == 0) _setPageScrollBlocked(false);
  }

  Widget _absorbPageScroll(Widget child) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onTipPointerDown,
      onPointerUp: _onTipPointerUpOrCancel,
      onPointerCancel: _onTipPointerUpOrCancel,
      child: child,
    );
  }

  void _resetToCenteredExpanded() {
    _ballMode = false;
    _collapseController.value = 0;
  }

  void _syncEntrance(TipContent tip, bool disableAnim) {
    if (!tip.shouldShow) return;
    if (tip.presentationGeneration == _lastPlayedGeneration) return;
    _lastPlayedGeneration = tip.presentationGeneration;
    _resetToCenteredExpanded();
    if (disableAnim) {
      _enterController.value = 1;
      return;
    }
    _enterController.forward(from: 0);
  }

  Future<void> _collapseToIcon(Rect bounds) async {
    if (_ballMode) return;
    // 折叠到视口中心浮空球
    final center = Offset(bounds.width / 2, bounds.height / 2);
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    if (!disableAnim) {
      await _collapseController.forward(from: 0);
      if (!mounted) return;
    }
    setState(() {
      _ballMode = true;
      _ballPlacement = EdgeDockPlacement.floating(freeCenter: center);
      _collapseController.value = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ballController.showFloating(center);
    });
  }

  void _expandFromBall() {
    setState(() {
      _ballMode = false;
      _collapseController.value = 0;
    });
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    if (disableAnim) {
      _enterController.value = 1;
    } else {
      _enterController.forward(from: 0);
    }
  }

  Widget _pangbaoCircle({required double size}) {
    return ClipOval(
      child: Image.asset(
        kStartupIconAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildExpandedCard({
    required String displayText,
    required bool isStreaming,
    required bool canOpenCompanion,
    required ColorScheme scheme,
    required double maxH,
    required double maxW,
    required Rect bounds,
  }) {
    // 正文：可滚 + 轻点进陪伴；无 pan（避免抢 tap）
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenCompanion ? _openCompanionIfReady : null,
      child: Material(
        color: scheme.surfaceContainerHighest,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            16,
            12 + _kTipBadgeSize / 2,
            16,
            16,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ClinicAnswerBody(
              text: displayText,
              streaming: isStreaming,
              selectable: false,
              scrollable: false,
            ),
          ),
        ),
      ),
    );

    final collapsingCard = FadeTransition(
      opacity: _collapseFade,
      child: ScaleTransition(
        alignment: Alignment.topCenter,
        scale: _collapseScale,
        child: Padding(
          padding: const EdgeInsets.only(top: _kTipBadgeSize / 2),
          child: body,
        ),
      ),
    );

    return ScaleTransition(
      scale: _enterScale,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: SizedBox(
          width: maxW,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              collapsingCard,
              // 顶标：仅折叠，不拖
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _collapseToIcon(bounds),
                child: _pangbaoCircle(size: _kTipBadgeSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tip = ref.watch(tipProvider);
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    ref.listen<TipContent>(tipProvider, (prev, next) {
      if (prev == null) return;
      if (prev.presentationGeneration == next.presentationGeneration) return;
      if (!mounted) return;
      setState(() => _syncEntrance(next, disableAnim));
    });

    if (!tip.shouldShow) {
      if (_ballMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_resetToCenteredExpanded);
        });
      }
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncEntrance(tip, disableAnim);
    });

    final displayText = tip.answer.isNotEmpty ? tip.answer : tip.thinking;
    final isStreaming = tip.displayState == TipDisplayState.streaming;
    final canOpenCompanion = tip.canInjectToCompanion;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds =
            Offset.zero & Size(constraints.maxWidth, constraints.maxHeight);
        final tipSize = _estimateExpandedSize(bounds.size);
        final maxW = bounds.width - 48;
        final maxH = bounds.height * 0.4;

        if (_ballMode) {
          // 仅球态：拖贴边 / 拉出 / 点开
          return EdgeDockShell(
            bounds: bounds,
            controller: _ballController,
            initialPlacement: _ballPlacement,
            allowTopBottom: true,
            showEngagedScrim: false,
            occupancyId: kEdgeDockOccupancyTipId,
            occupancySticky: false,
            onInteractiveTap: _expandFromBall,
            onPullBusiness: _expandFromBall,
            onPointerOccupied: widget.onDraggingChanged,
            onPlacementChanged: (p) => _ballPlacement = p,
            child: Material(
              elevation: 2,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: _pangbaoCircle(size: kDefaultEdgeDockDiameter),
            ),
          );
        }

        final cx = bounds.width / 2;
        final cy = bounds.height / 3;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: cx - tipSize.width / 2,
              top: cy - tipSize.height / 2,
              width: tipSize.width,
              child: _absorbPageScroll(
                _buildExpandedCard(
                  displayText: displayText,
                  isStreaming: isStreaming,
                  canOpenCompanion: canOpenCompanion,
                  scheme: scheme,
                  maxH: maxH,
                  maxW: maxW,
                  bounds: bounds,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
