import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/ucg_media_url.dart';
import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';
import 'ucg_media_viewer.dart';
import 'ucg_network_image.dart';

const _kGridGap = 4.0;
const _kCellRadius = 13.0;
const _kReorderAnimDuration = Duration(milliseconds: 220);
const _kLongPressDelay = Duration(milliseconds: 180);
const _kDragFeedbackScale = 1.08;

/// 以格内按压点为锚，放大反馈时按中心外扩，避免左上角贴指针造成错位。
Offset _composeDragAnchorStrategy(Draggable<Object> draggable, BuildContext context, Offset position) {
  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) return Offset.zero;
  final local = renderBox.globalToLocal(position);
  final pad = renderBox.size * (_kDragFeedbackScale - 1) / 2;
  return local + Offset(pad.width, pad.height);
}

/// 拖拽图片时底部浮层删除区（仿微信「松手即可删除」）。
class UcgComposeDeleteOverlay extends StatelessWidget {
  const UcgComposeDeleteOverlay({
    super.key,
    required this.onAccept,
  });

  final ValueChanged<int> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, rejected) {
        final over = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 72,
          width: double.infinity,
          color: over ? const Color(0xFFE64340) : const Color(0xFFFA5151),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: over ? 1 : 0.9), size: 22),
              const SizedBox(height: 4),
              Text(
                over ? '松手即可删除' : '拖动到此处删除',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: over ? 1 : 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 3×3 图片九宫格（微信式拖拽实时让位；「+」占位添加；无常驻删除区）。
class UcgComposeImageGrid extends StatefulWidget {
  const UcgComposeImageGrid({
    super.key,
    required this.imageKeys,
    required this.cdnUrls,
    required this.busy,
    required this.canAddMore,
    required this.onReorder,
    this.addBusy = false,
    this.onAddTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final List<String> imageKeys;
  final Map<String, String> cdnUrls;
  /// 禁用拖拽（发布中 / 润笔中）。
  final bool busy;
  /// 「+」格 loading（选图上传中），不影响拖拽结构。
  final bool addBusy;
  final bool canAddMore;
  final void Function(int from, int to) onReorder;
  final VoidCallback? onAddTap;
  final void Function(int index)? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  State<UcgComposeImageGrid> createState() => _UcgComposeImageGridState();
}

class _UcgComposeImageGridState extends State<UcgComposeImageGrid> {
  int? _dragFromIndex;
  int? _hoverIndex;
  var _reorderCommitted = false;

  int get _itemCount => widget.imageKeys.length + (widget.canAddMore ? 1 : 0);

  List<String> get _displayKeys {
    final keys = widget.imageKeys;
    final from = _dragFromIndex;
    final to = _hoverIndex;
    if (from == null || to == null || from == to) return keys;
    final next = List<String>.from(keys);
    final item = next.removeAt(from);
    next.insert(to.clamp(0, next.length), item);
    return next;
  }

  int _slotOf(String objectKey) {
    final slot = _displayKeys.indexOf(objectKey);
    return slot < 0 ? 0 : slot;
  }

  void _clearDragState() {
    if (_dragFromIndex == null && _hoverIndex == null && !_reorderCommitted) return;
    setState(() {
      _dragFromIndex = null;
      _hoverIndex = null;
      _reorderCommitted = false;
    });
  }

  void _onDragStarted(int index) {
    setState(() {
      _dragFromIndex = index;
      _hoverIndex = index;
      _reorderCommitted = false;
    });
    widget.onDragStarted?.call(index);
  }

  void _setHoverSlot(int slot) {
    if (_hoverIndex == slot) return;
    setState(() => _hoverIndex = slot);
  }

  void _commitReorder(int from, int to) {
    if (from == to || _reorderCommitted) return;
    _reorderCommitted = true;
    widget.onReorder(from, to);
  }

  void _onDragEnd(DraggableDetails details) {
    final from = _dragFromIndex;
    final to = _hoverIndex;
    if (!_reorderCommitted && !details.wasAccepted && from != null && to != null && from != to) {
      _commitReorder(from, to);
    }
    _clearDragState();
    widget.onDragEnded?.call();
  }

  void _openLightbox(BuildContext context, int index) {
    if (index < 0 || index >= widget.imageKeys.length) return;
    final urls = widget.imageKeys
        .map((k) => UcgMediaUrl.resolveUrl(objectKey: k, cdnUrl: widget.cdnUrls[k]))
        .toList(growable: false);
    unawaited(showUcgPhotoLightbox(context, urls: urls, initialIndex: index));
  }

  Offset _cellOrigin(int slot, double cellSize) {
    final col = slot % 3;
    final row = slot ~/ 3;
    return Offset(col * (cellSize + _kGridGap), row * (cellSize + _kGridGap));
  }

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cellSize = (width - _kGridGap * 2) / 3;
        final rows = (_itemCount + 2) ~/ 3;
        final height = rows * cellSize + (rows - 1) * _kGridGap;
        final dragging = _dragFromIndex != null;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.imageKeys.length; i++)
                _buildImageCell(context, i, cellSize),
              if (widget.canAddMore) _buildAddCell(cellSize),
              if (dragging)
                for (var slot = 0; slot < widget.imageKeys.length; slot++)
                  Positioned(
                    left: _cellOrigin(slot, cellSize).dx,
                    top: _cellOrigin(slot, cellSize).dy,
                    width: cellSize,
                    height: cellSize,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (d) => d.data != slot,
                      onMove: (_) => _setHoverSlot(slot),
                      onLeave: (_) {
                        if (_hoverIndex == slot) _setHoverSlot(_dragFromIndex ?? slot);
                      },
                      onAcceptWithDetails: (d) => _commitReorder(d.data, slot),
                      builder: (_, __, ___) => const SizedBox.expand(),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageCell(BuildContext context, int originalIndex, double cellSize) {
    final objectKey = widget.imageKeys[originalIndex];
    final slot = _slotOf(objectKey);
    final origin = _cellOrigin(slot, cellSize);
    final isDragging = _dragFromIndex == originalIndex;

    final tile = _ImageTile(
      key: ValueKey('tile-$objectKey'),
      objectKey: objectKey,
      cdnUrl: widget.cdnUrls[objectKey],
      size: cellSize,
    );

    Widget cell = tile;
    if (isDragging) {
      cell = Opacity(opacity: 0.35, child: tile);
    } else if (!widget.busy) {
      cell = GestureDetector(
        onTap: () => _openLightbox(context, originalIndex),
        behavior: HitTestBehavior.opaque,
        child: tile,
      );
    }

    if (widget.busy) {
      return AnimatedPositioned(
        key: ValueKey(objectKey),
        duration: _kReorderAnimDuration,
        curve: Curves.easeOutCubic,
        left: origin.dx,
        top: origin.dy,
        width: cellSize,
        height: cellSize,
        child: cell,
      );
    }

    return AnimatedPositioned(
      key: ValueKey(objectKey),
      duration: _kReorderAnimDuration,
      curve: Curves.easeOutCubic,
      left: origin.dx,
      top: origin.dy,
      width: cellSize,
      height: cellSize,
      child: _ComposeDraggableCell(
        data: originalIndex,
        onDragStarted: () => _onDragStarted(originalIndex),
        onDragEnd: _onDragEnd,
        feedback: _DragLiftFeedback(
          objectKey: objectKey,
          cdnUrl: widget.cdnUrls[objectKey],
          cellSize: cellSize,
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: tile),
        child: cell,
      ),
    );
  }

  Widget _buildAddCell(double cellSize) {
    final slot = widget.imageKeys.length;
    final origin = _cellOrigin(slot, cellSize);

    return AnimatedPositioned(
      key: const ValueKey('compose-add-tile'),
      duration: _kReorderAnimDuration,
      curve: Curves.easeOutCubic,
      left: origin.dx,
      top: origin.dy,
      width: cellSize,
      height: cellSize,
      child: _AddTile(size: cellSize, busy: widget.addBusy, onTap: widget.onAddTap),
    );
  }
}

/// 拖拽浮层：原位略放大 + 阴影，随手势移动时以按压点为锚。
class _DragLiftFeedback extends StatelessWidget {
  const _DragLiftFeedback({
    required this.objectKey,
    required this.cellSize,
    this.cdnUrl,
  });

  final String objectKey;
  final double cellSize;
  final String? cdnUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kCellRadius)),
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Transform.scale(
          scale: _kDragFeedbackScale,
          child: _ImageTile(
            objectKey: objectKey,
            cdnUrl: cdnUrl,
            size: cellSize,
          ),
        ),
      ),
    );
  }
}

/// 全平台 [LongPressDraggable]：长按完成即在原位抬起浮层，无需先移动。
class _ComposeDraggableCell extends StatelessWidget {
  const _ComposeDraggableCell({
    required this.data,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.feedback,
    required this.childWhenDragging,
    required this.child,
  });

  final int data;
  final VoidCallback onDragStarted;
  final void Function(DraggableDetails details) onDragEnd;
  final Widget feedback;
  final Widget childWhenDragging;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: data,
      delay: _kLongPressDelay,
      dragAnchorStrategy: _composeDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnd,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.busy, this.onTap});

  final double size;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final fg = tokens?.onShell ?? scheme.onSurface;
    final fill = tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.06);

    return Material(
      color: Color.alphaBlend(Colors.white.withValues(alpha: 0.55), fill),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCellRadius),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Center(
          child: busy
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg.withValues(alpha: 0.35),
                  ),
                )
              : Icon(
                  Icons.add,
                  size: 36,
                  color: fg.withValues(alpha: 0.35),
                ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    super.key,
    required this.objectKey,
    this.cdnUrl,
    this.size,
  });

  final String objectKey;
  final String? cdnUrl;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final url = UcgMediaUrl.resolveUrl(objectKey: objectKey, cdnUrl: cdnUrl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCellRadius),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCellRadius),
        child: UcgNetworkImage(
          key: ValueKey(url),
          url: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
