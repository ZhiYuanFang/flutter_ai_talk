import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/ucg_media_url.dart';
import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';
import 'ucg_compose_local_preview.dart';
import 'ucg_media_viewer.dart';

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

/// 九宫格单格：本地 path 或远程 objectKey 预览。
class UcgComposeGridCell {
  const UcgComposeGridCell({
    required this.id,
    this.localPath,
    this.localBytes,
    this.objectKey,
    this.cdnUrl,
  });

  final String id;
  final String? localPath;
  final Uint8List? localBytes;
  final String? objectKey;
  final String? cdnUrl;
}

/// 3×3 图片九宫格（微信式拖拽实时让位；「+」占位添加；无常驻删除区）。
class UcgComposeImageGrid extends StatefulWidget {
  const UcgComposeImageGrid({
    super.key,
    required this.cells,
    required this.busy,
    required this.canAddMore,
    required this.onReorder,
    this.onAddTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final List<UcgComposeGridCell> cells;
  /// 禁用拖拽（发布中 / 润笔中）。
  final bool busy;
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

  int get _itemCount => widget.cells.length + (widget.canAddMore ? 1 : 0);

  List<UcgComposeGridCell> get _displayCells {
    final cells = widget.cells;
    final from = _dragFromIndex;
    final to = _hoverIndex;
    if (from == null || to == null || from == to) return cells;
    final next = List<UcgComposeGridCell>.from(cells);
    final item = next.removeAt(from);
    next.insert(to.clamp(0, next.length), item);
    return next;
  }

  int _slotOf(String cellId) {
    final slot = _displayCells.indexWhere((c) => c.id == cellId);
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
    if (index < 0 || index >= widget.cells.length) return;
    final urls = widget.cells
        .map((c) => UcgMediaUrl.resolveUrl(objectKey: c.objectKey ?? '', cdnUrl: c.cdnUrl))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    if (urls.isEmpty) return;
    unawaited(showUcgPhotoLightbox(context, urls: urls, initialIndex: index.clamp(0, urls.length - 1)));
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
              for (var i = 0; i < widget.cells.length; i++)
                _buildImageCell(context, i, cellSize),
              if (widget.canAddMore) _buildAddCell(cellSize),
              if (dragging)
                for (var slot = 0; slot < widget.cells.length; slot++)
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
    final gridCell = widget.cells[originalIndex];
    final slot = _slotOf(gridCell.id);
    final origin = _cellOrigin(slot, cellSize);
    final isDragging = _dragFromIndex == originalIndex;

    final tile = _ImageTile(
      key: ValueKey('tile-${gridCell.id}'),
      cell: gridCell,
      size: cellSize,
    );

    Widget child = tile;
    if (isDragging) {
      child = Opacity(opacity: 0.35, child: tile);
    } else if (!widget.busy) {
      child = GestureDetector(
        onTap: () => _openLightbox(context, originalIndex),
        behavior: HitTestBehavior.opaque,
        child: tile,
      );
    }

    if (widget.busy) {
      return AnimatedPositioned(
        key: ValueKey(gridCell.id),
        duration: _kReorderAnimDuration,
        curve: Curves.easeOutCubic,
        left: origin.dx,
        top: origin.dy,
        width: cellSize,
        height: cellSize,
        child: child,
      );
    }

    return AnimatedPositioned(
      key: ValueKey(gridCell.id),
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
          cell: gridCell,
          cellSize: cellSize,
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: tile),
        child: child,
      ),
    );
  }

  Widget _buildAddCell(double cellSize) {
    final slot = widget.cells.length;
    final origin = _cellOrigin(slot, cellSize);

    return AnimatedPositioned(
      key: const ValueKey('compose-add-tile'),
      duration: _kReorderAnimDuration,
      curve: Curves.easeOutCubic,
      left: origin.dx,
      top: origin.dy,
      width: cellSize,
      height: cellSize,
      child: _AddTile(size: cellSize, onTap: widget.onAddTap),
    );
  }
}

/// 拖拽浮层：原位略放大 + 阴影，随手势移动时以按压点为锚。
class _DragLiftFeedback extends StatelessWidget {
  const _DragLiftFeedback({
    required this.cell,
    required this.cellSize,
  });

  final UcgComposeGridCell cell;
  final double cellSize;

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
            cell: cell,
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
  const _AddTile({required this.size, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final fg = tokens?.onRecordsCard ?? scheme.onSurface;
    final fill = tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.06);

    return Material(
      color: Color.alphaBlend(Colors.white.withValues(alpha: 0.55), fill),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCellRadius),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Icon(
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
    required this.cell,
    this.size,
  });

  final UcgComposeGridCell cell;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCellRadius),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCellRadius),
        child: UcgComposeMediaPreview(
          key: ValueKey('preview-${cell.id}-${cell.objectKey ?? cell.localPath}'),
          localPath: cell.localPath,
          localBytes: cell.localBytes,
          objectKey: cell.objectKey,
          cdnUrl: cell.cdnUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
