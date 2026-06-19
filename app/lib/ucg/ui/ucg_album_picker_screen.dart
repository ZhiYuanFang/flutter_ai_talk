import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../data/history_edit_media_item.dart';
import '../data/ucg_album_picker.dart';
import '../data/ucg_album_permission.dart';
import '../data/ucg_album_selection.dart';
import '../data/ucg_repository.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ui/history_event_media_picker.dart';
import 'widgets/ucg_media_viewer.dart';

/// 相册查询过滤：放宽尺寸约束并固定排序，减轻部分 Android 机型 MediaStore 查询失败。
FilterOptionGroup _ucgAlbumFilterOption() => FilterOptionGroup(
      imageOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      videoOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      orders: const [
        OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

/// 全屏自建相册（玻璃顶栏 + 选择侧互斥）。
class UcgAlbumPickerScreen extends StatefulWidget {
  const UcgAlbumPickerScreen({
    super.key,
    required this.repo,
    this.maxPhotos = 9,
    this.deferUpload = false,
    this.lockedPickKind = UcgAlbumLockedPickKind.none,
  });

  final UcgRepository repo;
  final int maxPhotos;
  /// 为 true 时返回本地 [HistoryEditMediaItem] 列表，不上传 OSS。
  final bool deferUpload;
  /// 打开前已确定媒体类型（如 compose 已有图时再追加，须锁定为仅图片）。
  final UcgAlbumLockedPickKind lockedPickKind;

  @override
  State<UcgAlbumPickerScreen> createState() => _UcgAlbumPickerScreenState();
}

class _UcgAlbumPickerScreenState extends State<UcgAlbumPickerScreen> {
  static const _pageSize = 80;

  late final UcgAlbumSelectionController _selection;
  final _scrollController = ScrollController();

  AssetPathEntity? _album;
  final _assets = <AssetEntity>[];
  var _loading = true;
  var _loadingMore = false;
  var _uploading = false;
  var _hasMore = true;
  var _page = 0;
  var _pageBatchSize = _pageSize;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selection = UcgAlbumSelectionController(
      maxPhotos: widget.maxPhotos,
      lockedKind: widget.lockedPickKind,
    );
    _scrollController.addListener(_onScroll);
    unawaited(_initAlbum());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selection.dispose();
    super.dispose();
  }

  Future<void> _initAlbum() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final ok = await ucgEnsureAlbumPermission();
    if (!ok) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '需要相册权限才能选择图片或视频';
        });
      }
      return;
    }

    try {
      final filter = _ucgAlbumFilterOption();
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
        filterOption: filter,
      );
      if (paths.isEmpty) {
        if (mounted) setState(() { _loading = false; _error = '相册为空'; });
        return;
      }
      for (final candidate in _albumCandidates(paths)) {
        if (await _tryBindAlbum(candidate)) return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败';
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UcgAlbumPickerScreen._initAlbum failed: $e\n$st');
      }
      if (mounted) setState(() { _loading = false; _error = '加载相册失败'; });
    }
  }

  Iterable<AssetPathEntity> _albumCandidates(List<AssetPathEntity> paths) sync* {
    for (final p in paths) {
      if (p.isAll) yield p;
    }
    final named = paths.where((p) => !p.isAll).toList()
      ..sort((a, b) {
        int score(AssetPathEntity p) {
          final n = p.name.toLowerCase();
          if (n.contains('camera') || n.contains('相机')) return 0;
          if (n.contains('screenshot') || n.contains('截图')) return 1;
          return 2;
        }
        return score(a).compareTo(score(b));
      });
    for (final p in named) {
      yield p;
    }
  }

  Future<bool> _tryBindAlbum(AssetPathEntity album) async {
    try {
      final batch = await _fetchAssetPage(album, 0);
      if (!mounted) return true;
      _album = album;
      setState(() {
        _assets
          ..clear()
          ..addAll(batch);
        _page = 0;
        _hasMore = batch.length >= _pageBatchSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
      return true;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('album "${album.name}" (${album.id}) load failed: $e\n$st');
      }
      return false;
    }
  }

  /// 分页拉取；华为等机型 `getAssetListPaged` / `getAssetListRange` 可能均失败，由上层换相册或系统选择器降级。
  Future<List<AssetEntity>> _fetchAssetPage(AssetPathEntity album, int page) async {
    final sizes = page == 0 ? <int>[_pageSize, 40, 20] : <int>[_pageBatchSize];
    Object? lastError;
    for (final size in sizes) {
      try {
        final batch = await album.getAssetListPaged(page: page, size: size);
        if (page == 0) _pageBatchSize = size;
        return batch;
      } on Object catch (e, st) {
        lastError = e;
        if (kDebugMode) {
          debugPrint(
            'getAssetListPaged failed album=${album.id} page=$page size=$size: $e\n$st',
          );
        }
        try {
          final total = await album.assetCountAsync;
          final start = page * size;
          if (start >= total) return const [];
          final end = (start + size).clamp(0, total);
          final batch = await album.getAssetListRange(start: start, end: end);
          if (page == 0) _pageBatchSize = size;
          return batch;
        } on Object catch (e2, st2) {
          lastError = e2;
          if (kDebugMode) {
            debugPrint(
              'getAssetListRange failed album=${album.id} page=$page size=$size: $e2\n$st2',
            );
          }
        }
      }
    }
    Error.throwWithStackTrace(lastError ?? StateError('album load failed'), StackTrace.current);
  }

  Future<void> _fallbackSystemPicker() async {
    if (kIsWeb) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultipleMedia(limit: widget.maxPhotos);
    if (!mounted) return;
    if (picked.isEmpty) {
      Navigator.pop(context);
      return;
    }
    var hasImage = false;
    var hasVideo = false;
    for (final f in picked) {
      final mime = f.mimeType ?? '';
      if (mime.startsWith('video/')) {
        hasVideo = true;
      } else {
        hasImage = true;
      }
    }
    if (hasImage && hasVideo) {
      _toast('不能同时选择图片和视频');
      return;
    }
    if (widget.lockedPickKind == UcgAlbumLockedPickKind.photos && hasVideo) {
      _toast('已选择图片，不能再选视频');
      return;
    }
    if (widget.lockedPickKind == UcgAlbumLockedPickKind.video && hasImage) {
      _toast('已选择视频，不能再选图片');
      return;
    }
    if (widget.deferUpload) {
      if (hasVideo) {
        if (picked.length > 1) {
          _toast('不能同时选择图片和视频');
          return;
        }
        Navigator.pop(
          context,
          [HistoryEditLocalFile(path: picked.first.path, isVideo: true)],
        );
        return;
      }
      final items = <HistoryEditLocalFile>[];
      for (final f in picked) {
        Uint8List? bytes;
        try {
          bytes = await f.readAsBytes();
        } catch (_) {}
        items.add(HistoryEditLocalFile(path: f.path, isVideo: false, bytes: bytes));
      }
      Navigator.pop(context, items);
      return;
    }
    _toast('系统相册选择暂不支持直接上传，请重试');
  }

  Future<void> _loadPage(int page, {required bool reset}) async {
    final album = _album;
    if (album == null) return;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final batch = await _fetchAssetPage(album, page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _assets
            ..clear()
            ..addAll(batch);
          _page = 0;
        } else {
          _assets.addAll(batch);
          _page = page;
        }
        _hasMore = batch.length >= _pageBatchSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UcgAlbumPickerScreen._loadPage failed page=$page: $e\n$st');
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = '加载失败';
        });
      }
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    unawaited(_loadPage(_page + 1, reset: false));
  }

  Future<void> _complete() async {
    if (!_selection.hasSelection || _uploading) return;
    if (widget.lockedPickKind == UcgAlbumLockedPickKind.photos &&
        _selection.selected.any((e) => e.type == AssetType.video)) {
      _toast('已选择图片，不能再选视频');
      return;
    }
    if (widget.lockedPickKind == UcgAlbumLockedPickKind.video &&
        _selection.selected.any((e) => e.type == AssetType.image)) {
      _toast('已选择视频，不能再选图片');
      return;
    }
    setState(() => _uploading = true);
    try {
      if (widget.deferUpload) {
        final items = await historyMediaItemsFromAssets(_selection.selected);
        if (!mounted) return;
        if (items.isEmpty) {
          _toast('选择失败');
          return;
        }
        Navigator.pop(context, items);
        return;
      }
      final result = await ucgUploadAlbumAssets(
        repo: widget.repo,
        assets: _selection.selected,
      );
      if (!mounted) return;
      if (result == null || result.isEmpty) {
        _toast('上传失败');
        return;
      }
      Navigator.pop(context, result);
    } catch (_) {
      _toast('上传失败');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final shellFg = tokens?.onShell ?? scheme.onSurface;

    return Scaffold(
      backgroundColor: shellBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: shellFg)),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _selection,
                      builder: (_, __) => Text(
                        _selection.selectionLabel(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: shellFg.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _selection,
                    builder: (_, __) {
                      final enabled = _selection.hasSelection && !_uploading;
                      return FilledButton(
                        onPressed: enabled ? _complete : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: const StadiumBorder(),
                          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
                        ),
                        child: _uploading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Text('完成'),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(shellFg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color shellFg) {
    if (_loading && _assets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: shellFg)),
              const SizedBox(height: 12),
              if (_error!.contains('权限'))
                TextButton(
                  onPressed: () => unawaited(ucgOpenAppSettingsForAlbum()),
                  child: const Text('打开设置'),
                )
              else ...[
                TextButton(
                  onPressed: _loading ? null : () => unawaited(_initAlbum()),
                  child: const Text('重试'),
                ),
                if (!kIsWeb)
                  TextButton(
                    onPressed: _loading ? null : () => unawaited(_fallbackSystemPicker()),
                    child: const Text('使用系统相册'),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _assets.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _assets.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return _AssetCell(
          key: ValueKey(_assets[index].id),
          asset: _assets[index],
          selection: _selection,
        );
      },
    );
  }
}

class _AssetCell extends StatefulWidget {
  const _AssetCell({
    super.key,
    required this.asset,
    required this.selection,
  });

  final AssetEntity asset;
  final UcgAlbumSelectionController selection;

  @override
  State<_AssetCell> createState() => _AssetCellState();
}

class _AssetCellState extends State<_AssetCell> {
  late final Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.selection,
      builder: (context, _) {
        final disabled = widget.selection.isDisabled(widget.asset);
        final selected = widget.selection.isSelected(widget.asset);
        final canSelect = widget.selection.canTap(widget.asset) || selected;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: disabled
                  ? null
                  : () => unawaited(showUcgAssetPreview(context, widget.asset)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List?>(
                    future: _thumbnailFuture,
                    builder: (context, snap) {
                      if (snap.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(snap.data!, fit: BoxFit.cover),
                        );
                      }
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                  if (widget.asset.type == AssetType.video)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ucgFormatAssetDuration(widget.asset.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: canSelect ? () => widget.selection.toggle(widget.asset) : null,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _SelectionBadge(
                      selected: selected,
                      index: selected && widget.asset.type != AssetType.video
                          ? widget.selection.selected
                                  .indexWhere((e) => e.id == widget.asset.id) +
                              1
                          : null,
                      primary: scheme.primary,
                      onPrimary: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            if (disabled)
              Positioned.fill(
                child: AbsorbPointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({
    required this.selected,
    required this.primary,
    required this.onPrimary,
    this.index,
  });

  final bool selected;
  final int? index;
  final Color primary;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? primary : Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: index != null
          ? Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}