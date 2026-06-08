import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/ucg_album_picker.dart';
import '../data/ucg_album_permission.dart';
import '../data/ucg_album_selection.dart';
import '../data/ucg_repository.dart';
import '../../theme/app_visual_tokens.dart';

/// 全屏自建相册（玻璃顶栏 + 选择侧互斥）。
class UcgAlbumPickerScreen extends StatefulWidget {
  const UcgAlbumPickerScreen({
    super.key,
    required this.repo,
    this.maxPhotos = 9,
  });

  final UcgRepository repo;
  final int maxPhotos;

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _selection = UcgAlbumSelectionController(maxPhotos: widget.maxPhotos);
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
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      if (paths.isEmpty) {
        if (mounted) setState(() { _loading = false; _error = '相册为空'; });
        return;
      }
      _album = paths.first;
      await _loadPage(0, reset: true);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '加载相册失败'; });
    }
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
      final batch = await album.getAssetListPaged(page: page, size: _pageSize);
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
        _hasMore = batch.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
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
    setState(() => _uploading = true);
    try {
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
                ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
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
              asset: _assets[index],
              selection: _selection,
            );
          },
        );
      },
    );
  }
}

class _AssetCell extends StatelessWidget {
  const _AssetCell({
    required this.asset,
    required this.selection,
  });

  final AssetEntity asset;
  final UcgAlbumSelectionController selection;

  @override
  Widget build(BuildContext context) {
    final disabled = selection.isDisabled(asset);
    final selected = selection.isSelected(asset);
    final canTap = selection.canTap(asset) || selected;

    return GestureDetector(
      onTap: canTap ? () => selection.toggle(asset) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              const ThumbnailSize.square(200),
            ),
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
          if (asset.type == AssetType.video)
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
                  ucgFormatAssetDuration(asset.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: asset.type == AssetType.video
                    ? null
                    : Center(
                        child: Text(
                          '${selection.selected.indexWhere((e) => e.id == asset.id) + 1}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          if (disabled)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}