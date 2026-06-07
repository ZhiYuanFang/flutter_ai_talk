import 'package:flutter/material.dart';

/// Horizontal slide action with a fixed-width reveal (e.g. delete on 我的动态).
///
/// Swipe only opens/closes the action pane; [onDelete] runs when the user taps
/// the revealed action control (not on gesture end).
class UcgLimitedSlideAction extends StatefulWidget {
  const UcgLimitedSlideAction({
    super.key,
    required this.child,
    required this.onDelete,
    required this.actionBackground,
    required this.actionIcon,
    this.actionWidth = 60,
  });

  final Widget child;
  final Future<bool> Function() onDelete;
  final double actionWidth;
  final Color actionBackground;
  final Widget actionIcon;

  @override
  State<UcgLimitedSlideAction> createState() => _UcgLimitedSlideActionState();
}

class _UcgLimitedSlideActionState extends State<UcgLimitedSlideAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapController;
  double _dragExtent = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double get _offset => _dragging ? _dragExtent : _snapController.value * widget.actionWidth;

  void _onDragStart(DragStartDetails _) {
    _snapController.stop();
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent - details.delta.dx).clamp(0.0, widget.actionWidth);
    });
  }

  Future<void> _onDragEnd(DragEndDetails _) async {
    final shouldOpen = _dragExtent > widget.actionWidth * 0.5;
    setState(() {
      _dragging = false;
      _dragExtent = 0;
    });
    await _snapController.animateTo(shouldOpen ? 1 : 0);
  }

  Future<void> _onDeleteTap() async {
    if (_offset < widget.actionWidth * 0.5) return;
    final deleted = await widget.onDelete();
    if (deleted && mounted) {
      await _snapController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: widget.actionWidth,
          child: Material(
            color: widget.actionBackground,
            child: InkWell(
              onTap: _onDeleteTap,
              child: Center(child: widget.actionIcon),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(-_offset, 0),
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
