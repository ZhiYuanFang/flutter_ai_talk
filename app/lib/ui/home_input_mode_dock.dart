import 'dart:async';

import 'package:flutter/material.dart';

import '../config/home_input_dock_store.dart';
import '../data/home_input_dock_geometry.dart';
import '../theme/app_theme_scope.dart';
import 'home_input_channel.dart';

/// 贴边半露、可拖动吸附的输入模式切换器。
class HomeInputModeDock extends StatefulWidget {
  const HomeInputModeDock({
    super.key,
    required this.bounds,
    required this.bottomInputPanelHeight,
    required this.currentChannel,
    required this.showButtonsOption,
    required this.onChannelSelected,
    this.restrictToHorizontalEdges = false,
  });

  final Rect bounds;
  final double bottomInputPanelHeight;
  final HomeInputChannel currentChannel;
  final bool showButtonsOption;
  final ValueChanged<HomeInputChannel> onChannelSelected;

  /// Web：仅左右吸附。
  final bool restrictToHorizontalEdges;

  @override
  State<HomeInputModeDock> createState() => _HomeInputModeDockState();
}

class _HomeInputModeDockState extends State<HomeInputModeDock> {
  var _expanded = false;
  var _edge = kHomeInputDockDefaultEdge;
  var _along = kHomeInputDockDefaultAlong;
  Offset? _dragCenter;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDockPosition());
  }

  Future<void> _loadDockPosition() async {
    final snap = await HomeInputDockStore.load();
    if (!mounted) return;
    setState(() {
      _edge = snap.edge;
      _along = snap.along;
      _loaded = true;
    });
  }

  Offset get _snappedCenter => dockCircleCenterForSnapped(
        edge: _edge,
        along: _along,
        bounds: widget.bounds,
      );

  Offset get _displayCenter => _dragCenter ?? _snappedCenter;

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _persistSnap(DockEdge edge, double along) async {
    await HomeInputDockStore.save(edge, along);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    final local = box?.globalToLocal(details.globalPosition) ?? details.localPosition;
    setState(() {
      _expanded = false;
      _dragCenter = clampDockCenterForDrag(local, widget.bounds);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final center = _dragCenter;
    if (center == null) return;
    final snap = snapDockToNearestEdge(
      center,
      widget.bounds,
      allowTopBottom: !widget.restrictToHorizontalEdges,
    );
    setState(() {
      _edge = snap.edge;
      _along = snap.along;
      _dragCenter = null;
    });
    unawaited(_persistSnap(snap.edge, snap.along));
  }

  void _selectChannel(HomeInputChannel channel) {
    widget.onChannelSelected(channel);
    _collapse();
  }

  List<HomeInputChannel> get _availableChannels {
    if (widget.showButtonsOption) {
      return HomeInputChannel.values;
    }
    return const [HomeInputChannel.voice, HomeInputChannel.text];
  }

  /// 展开菜单沿主轴尺寸（与 [_buildExpandedMenu] 布局一致）。
  double get _menuMainAxisExtent {
    final count = _availableChannels.length;
    const itemSize = 40.0;
    const padding = 8.0;
    const itemGap = 4.0;
    return padding + count * itemSize + (count - 1) * itemGap;
  }

  /// 集群左上角：展开时保持 handle 圆心不变，菜单向屏内展开。
  Offset _clusterTopLeft(Offset handleCenter) {
    const clusterGap = 6.0;
    if (!_expanded) {
      return Offset(
        handleCenter.dx - kHomeInputDockRadius,
        handleCenter.dy - kHomeInputDockRadius,
      );
    }
    return switch (_edge) {
      DockEdge.right => Offset(
          handleCenter.dx - kHomeInputDockRadius - clusterGap - _menuMainAxisExtent,
          handleCenter.dy - kHomeInputDockRadius,
        ),
      DockEdge.left || DockEdge.top => Offset(
          handleCenter.dx - kHomeInputDockRadius,
          handleCenter.dy - kHomeInputDockRadius,
        ),
      DockEdge.bottom => Offset(
          handleCenter.dx - kHomeInputDockRadius,
          handleCenter.dy - kHomeInputDockRadius - clusterGap - _menuMainAxisExtent,
        ),
    };
  }

  IconData _iconFor(HomeInputChannel channel) {
    return switch (channel) {
      HomeInputChannel.voice => Icons.mic_rounded,
      HomeInputChannel.text => Icons.keyboard_rounded,
      HomeInputChannel.buttons => Icons.grid_view_rounded,
    };
  }

  String _labelFor(HomeInputChannel channel) {
    return switch (channel) {
      HomeInputChannel.voice => '语音',
      HomeInputChannel.text => '文字',
      HomeInputChannel.buttons => '按钮',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final center = _displayCenter;
    final clusterOrigin = _clusterTopLeft(center);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_expanded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: widget.bottomInputPanelHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          left: clusterOrigin.dx,
          top: clusterOrigin.dy,
          child: _buildDockCluster(context),
        ),
      ],
    );
  }

  Widget _buildDockCluster(BuildContext context) {
    final handle = _buildSemicircleHandle(context, widget.currentChannel);
    final semicircle = GestureDetector(
      onTap: _expanded ? _collapse : _toggleExpanded,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: handle,
    );

    if (!_expanded) return semicircle;

    final menu = _buildExpandedMenu(context);
    return switch (_edge) {
      DockEdge.right => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [menu, const SizedBox(width: 6), semicircle],
        ),
      DockEdge.left => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [semicircle, const SizedBox(width: 6), menu],
        ),
      DockEdge.bottom => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [menu, const SizedBox(height: 6), semicircle],
        ),
      DockEdge.top => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [semicircle, const SizedBox(height: 6), menu],
        ),
    };
  }

  Widget _buildExpandedMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontal = _edge == DockEdge.top || _edge == DockEdge.bottom;

    final items = _availableChannels
        .map(
          (channel) => _menuItem(
            context: context,
            channel: channel,
            selected: channel == widget.currentChannel,
            onTap: () => _selectChannel(channel),
          ),
        )
        .toList();

    return Material(
      elevation: 4,
      shadowColor: scheme.primary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      color: themePrimaryBlend(context, alpha: 0.22),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: horizontal
            ? Row(mainAxisSize: MainAxisSize.min, children: _intersperse(items, const SizedBox(width: 4)))
            : Column(mainAxisSize: MainAxisSize.min, children: _intersperse(items, const SizedBox(height: 4))),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget spacer) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(spacer);
      out.add(items[i]);
    }
    return out;
  }

  Widget _menuItem({
    required BuildContext context,
    required HomeInputChannel channel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _labelFor(channel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _iconFor(channel),
            size: 22,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSemicircleHandle(BuildContext context, HomeInputChannel channel) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shadowColor: scheme.primary.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      color: themePrimaryBlend(context, alpha: 0.24),
      child: SizedBox(
        width: kHomeInputDockDiameter,
        height: kHomeInputDockDiameter,
        child: Icon(
          _iconFor(channel),
          size: 22,
          color: scheme.primary,
        ),
      ),
    );
  }
}
