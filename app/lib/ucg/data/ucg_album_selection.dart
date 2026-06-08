import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

enum UcgAlbumPickMode { idle, photos, video }

/// 相册选择互斥：idle → 先选图 photo 模式 / 先选视频 video 模式。
class UcgAlbumSelectionController extends ChangeNotifier {
  UcgAlbumSelectionController({this.maxPhotos = 9});

  final int maxPhotos;
  final List<AssetEntity> _selected = [];

  UcgAlbumPickMode get mode {
    if (_selected.isEmpty) return UcgAlbumPickMode.idle;
    return _selected.first.type == AssetType.video
        ? UcgAlbumPickMode.video
        : UcgAlbumPickMode.photos;
  }

  List<AssetEntity> get selected => List.unmodifiable(_selected);

  bool get hasSelection => _selected.isNotEmpty;

  String selectionLabel() {
    if (_selected.isEmpty) return '选择图片或视频';
    if (mode == UcgAlbumPickMode.video) return '已选 1 个视频';
    return '已选 ${_selected.length}/$maxPhotos';
  }

  bool isSelected(AssetEntity asset) =>
      _selected.any((e) => e.id == asset.id);

  bool isDisabled(AssetEntity asset) {
    final m = mode;
    if (m == UcgAlbumPickMode.idle) return false;
    if (asset.type == AssetType.video) return m == UcgAlbumPickMode.photos;
    return m == UcgAlbumPickMode.video;
  }

  bool canTap(AssetEntity asset) {
    if (isDisabled(asset)) return false;
    if (isSelected(asset)) return true;
    if (asset.type == AssetType.video) return mode == UcgAlbumPickMode.idle;
    if (mode == UcgAlbumPickMode.video) return false;
    return _selected.length < maxPhotos;
  }

  void toggle(AssetEntity asset) {
    if (isSelected(asset)) {
      _selected.removeWhere((e) => e.id == asset.id);
      notifyListeners();
      return;
    }
    if (!canTap(asset)) return;
    if (asset.type == AssetType.video) {
      _selected
        ..clear()
        ..add(asset);
    } else {
      _selected.add(asset);
    }
    notifyListeners();
  }
}
