import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/history_edit_media_item.dart';
import '../../ucg/ui/widgets/ucg_media_viewer.dart';
import '../../ucg/ui/widgets/ucg_network_image.dart';

const _kStripHeight = 72.0;
const _kThumbSize = 64.0;
const _kStripGap = 8.0;
const _kThumbRadius = 10.0;

Offset _historyDragAnchorStrategy(Draggable<Object> draggable, BuildContext context, Offset position) {
  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) return Offset.zero;
  final local = renderBox.globalToLocal(position);
  const scale = 1.06;
  final pad = renderBox.size * (scale - 1) / 2;
  return local + Offset(pad.width, pad.height);
}

/// 历史编辑 Sheet 横向媒体条带：缩略图、右上角删除、长按拖拽排序。
class HistoryEventMediaStrip extends StatefulWidget {
  const HistoryEventMediaStrip({
    super.key,
    required this.items,
    required this.enabled,
    required this.onReorder,
    required this.onRemoveAt,
  });

  final List<HistoryEditMediaItem> items;
  final bool enabled;
  final void Function(int from, int to) onReorder;
  final void Function(int index) onRemoveAt;

  @override
  State<HistoryEventMediaStrip> createState() => _HistoryEventMediaStripState();
}

class _HistoryEventMediaStripState extends State<HistoryEventMediaStrip> {
  int? _dragFromIndex;
  int? _hoverIndex;
  var _reorderCommitted = false;

  List<HistoryEditMediaItem> get _displayItems {
    final items = widget.items;
    final from = _dragFromIndex;
    final to = _hoverIndex;
    if (from == null || to == null || from == to) return items;
    final next = List<HistoryEditMediaItem>.from(items);
    final item = next.removeAt(from);
    next.insert(to.clamp(0, next.length), item);
    return next;
  }

  int _slotOf(HistoryEditMediaItem item) {
    final slot = _displayItems.indexOf(item);
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final dragging = _dragFromIndex != null;
    final count = widget.items.length;
    final width = count * _kThumbSize + (count - 1) * _kStripGap;

    return SizedBox(
      height: _kStripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: _kStripHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                _buildCell(context, i),
              if (dragging && widget.enabled)
                for (var slot = 0; slot < widget.items.length; slot++)
                  Positioned(
                    left: slot * (_kThumbSize + _kStripGap),
                    top: 4,
                    width: _kThumbSize,
                    height: _kThumbSize,
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
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int originalIndex) {
    final item = widget.items[originalIndex];
    final slot = _slotOf(item);
    final left = slot * (_kThumbSize + _kStripGap);
    final isDragging = _dragFromIndex == originalIndex;

    final thumb = _HistoryMediaThumb(item: item, size: _kThumbSize);

    Widget cell = GestureDetector(
      onTap: () => unawaited(_openPreview(context, item)),
      behavior: HitTestBehavior.opaque,
      child: thumb,
    );
    if (isDragging) {
      cell = Opacity(opacity: 0.35, child: thumb);
    }

    if (widget.enabled && !isDragging) {
      cell = LongPressDraggable<int>(
        data: originalIndex,
        delay: const Duration(milliseconds: 180),
        dragAnchorStrategy: _historyDragAnchorStrategy,
        onDragStarted: () => _onDragStarted(originalIndex),
        onDragEnd: _onDragEnd,
        feedback: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kThumbRadius)),
          child: SizedBox(
            width: _kThumbSize,
            height: _kThumbSize,
            child: Transform.scale(scale: 1.06, child: thumb),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: thumb),
        child: cell,
      );
    }

    return AnimatedPositioned(
      key: ValueKey('history-media-$originalIndex-${item.hashCode}'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: left,
      top: 4,
      width: _kThumbSize,
      height: _kThumbSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          cell,
          if (widget.enabled)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => widget.onRemoveAt(originalIndex),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPreview(BuildContext context, HistoryEditMediaItem item) async {
    switch (item) {
      case HistoryEditRemoteImage(:final displayUrl):
        await showUcgPhotoLightbox(context, urls: [displayUrl]);
      case HistoryEditRemoteVideo(:final displayUrl):
        await showUcgVideoFullscreen(context, videoUrl: displayUrl);
      case HistoryEditLocalFile(:final path, :final isVideo):
        if (isVideo) {
          await showUcgVideoFullscreen(context, filePath: path);
        } else if (kIsWeb) {
          await showUcgLocalImageLightbox(context, url: path);
        } else {
          await showUcgLocalImageLightbox(context, filePath: path);
        }
    }
  }
}

class _HistoryMediaThumb extends StatelessWidget {
  const _HistoryMediaThumb({required this.item, required this.size});

  final HistoryEditMediaItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(_kThumbRadius);
    Widget child;
    switch (item) {
      case HistoryEditRemoteImage(:final displayUrl):
        child = UcgNetworkImage(url: displayUrl, width: size, height: size, fit: BoxFit.cover);
      case HistoryEditRemoteVideo(:final displayUrl):
        child = Stack(
          fit: StackFit.expand,
          children: [
            UcgNetworkImage(url: displayUrl, width: size, height: size, fit: BoxFit.cover),
            Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white.withValues(alpha: 0.92), size: 28),
            ),
          ],
        );
      case HistoryEditLocalFile(:final path, :final isVideo, :final bytes):
        if (kIsWeb) {
          child = Icon(isVideo ? Icons.videocam : Icons.image, size: 32);
        } else if (isVideo) {
          child = UcgLocalVideoThumb(
            filePath: path,
            posterBytes: bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        } else {
          child = Image.file(File(path), width: size, height: size, fit: BoxFit.cover);
        }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(borderRadius: border, child: child),
    );
  }
}
