import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

import '../data/history_edit_media_item.dart';
import '../ucg/data/ucg_album_picker.dart';
import '../ucg/data/ucg_repository.dart';
import '../ucg/data/ucg_album_selection.dart';
import '../ucg/ui/ucg_album_picker_screen.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

const _kMaxImages = 9;

/// 历史编辑：选择本地媒体（延迟上传至保存时 sync ON 分支）。
Future<List<HistoryEditMediaItem>?> pickHistoryEventMedia({
  required BuildContext context,
  required UcgRepository repo,
  required List<HistoryEditMediaItem> current,
}) async {
  final hasVideo = current.any((e) => e.isVideo);
  final imageCount = current.where((e) => e.isImage).length;
  if (hasVideo) {
    showAppToast('已有视频，不能再添加', tone: AppToastTone.error);
    return null;
  }
  if (imageCount >= _kMaxImages) {
    showAppToast('最多 $_kMaxImages 张图片', tone: AppToastTone.error);
    return null;
  }

  final pick = await showGlassAdaptiveBottomSheet<_UcgComposeEntryPick>(
    context: context,
    maxHeightFraction: 0.35,
    scrollable: false,
    useLightGlass: true,
    glassContentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
    bodyBuilder: (ctx) => _HistoryMediaEntryBody(showCamera: !kIsWeb),
  );
  if (pick == null || !context.mounted) return null;

  if (pick == _UcgComposeEntryPick.camera) {
    return _pickFromCamera(context, hasImages: imageCount > 0);
  }

  if (kIsWeb) {
    return _pickFromWeb(imageCount);
  }

  final remaining = _kMaxImages - imageCount;
  final picked = await Navigator.of(context).push<List<HistoryEditMediaItem>>(
    MaterialPageRoute(
      builder: (_) => UcgAlbumPickerScreen(
        repo: repo,
        maxPhotos: remaining,
        deferUpload: true,
        lockedPickKind:
            imageCount > 0 ? UcgAlbumLockedPickKind.photos : UcgAlbumLockedPickKind.none,
      ),
    ),
  );
  return picked;
}

enum _UcgComposeEntryPick { camera, gallery }

class _HistoryMediaEntryBody extends StatelessWidget {
  const _HistoryMediaEntryBody({required this.showCamera});

  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCamera)
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('拍摄'),
            onTap: () => Navigator.pop(context, _UcgComposeEntryPick.camera),
          ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('从手机相册选择'),
          onTap: () => Navigator.pop(context, _UcgComposeEntryPick.gallery),
        ),
      ],
    );
  }
}

Future<List<HistoryEditMediaItem>?> _pickFromCamera(
  BuildContext context, {
  required bool hasImages,
}) async {
  if (hasImages) {
    showAppToast('已有图片，不能再添加视频', tone: AppToastTone.error);
    return null;
  }
  final isVideo = await showGlassAdaptiveBottomSheet<bool>(
    context: context,
    maxHeightFraction: 0.32,
    scrollable: false,
    useLightGlass: true,
    glassContentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
    bodyBuilder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('拍照'),
          onTap: () => Navigator.pop(ctx, false),
        ),
        ListTile(
          leading: const Icon(Icons.videocam_outlined),
          title: const Text('录像'),
          onTap: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  if (isVideo == null) return null;
  final picker = ImagePicker();
  if (isVideo) {
    final file = await picker.pickVideo(source: ImageSource.camera);
    if (file == null) return null;
    return [HistoryEditLocalFile(path: file.path, isVideo: true)];
  }
  final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
  if (file == null) return null;
  return [HistoryEditLocalFile(path: file.path, isVideo: false)];
}

Future<List<HistoryEditMediaItem>?> _pickFromWeb(int imageCount) async {
  final remaining = _kMaxImages - imageCount;
  final picker = ImagePicker();
  final picked = await picker.pickMultipleMedia(limit: remaining);
  if (picked.isEmpty) return null;

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
    throw UcgAlbumMixedMediaException();
  }
  if (hasVideo) {
    if (picked.length > 1) throw UcgAlbumMixedMediaException();
    return [HistoryEditLocalFile(path: picked.first.path, isVideo: true)];
  }
  return picked.map((f) => HistoryEditLocalFile(path: f.path, isVideo: false)).toList();
}

/// 将相册 asset 转为本地文件条目（不上传）。
Future<List<HistoryEditMediaItem>> historyMediaItemsFromAssets(List<AssetEntity> assets) async {
  if (assets.isEmpty) return const [];
  final first = assets.first;
  if (first.type == AssetType.video) {
    if (assets.length > 1) return const [];
    final mediaUri = await first.getMediaUrl();
    final file = await first.loadFile(isOrigin: true) ?? await first.file;
    var path = file?.path;
    if (path == null || path.isEmpty) {
      path = mediaUri;
    }
    if (path == null || path.isEmpty) return const [];
    Uint8List? thumb;
    try {
      thumb = await first.thumbnailDataWithSize(const ThumbnailSize.square(1080));
    } catch (_) {}
    return [
      HistoryEditLocalFile(
        path: path,
        isVideo: true,
        bytes: thumb,
        mediaUri: mediaUri,
      ),
    ];
  }
  final out = <HistoryEditMediaItem>[];
  for (final asset in assets) {
    if (asset.type != AssetType.image) continue;
    final file = await asset.loadFile(isOrigin: false) ?? await asset.file;
    if (file == null) continue;
    Uint8List? bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {}
    if (bytes == null || bytes.isEmpty) {
      try {
        bytes = await asset.originBytes;
      } catch (_) {}
    }
    if (bytes == null || bytes.isEmpty) {
      try {
        bytes = await asset.thumbnailDataWithSize(const ThumbnailSize.square(1080));
      } catch (_) {}
    }
    out.add(HistoryEditLocalFile(path: file.path, isVideo: false, bytes: bytes));
  }
  return out;
}

bool validateHistoryEditMedia(List<HistoryEditMediaItem> items) {
  if (items.isEmpty) return true;
  final videos = items.where((e) => e.isVideo).length;
  final images = items.where((e) => e.isImage).length;
  if (videos > 1) return false;
  if (videos == 1 && images > 0) return false;
  if (images > _kMaxImages) return false;
  return true;
}

List<HistoryEditMediaItem> mergeHistoryPickedMedia({
  required List<HistoryEditMediaItem> current,
  required List<HistoryEditMediaItem> picked,
}) {
  if (picked.isEmpty) return current;
  if (picked.any((e) => e.isVideo)) {
    return picked.where((e) => e.isVideo).take(1).toList();
  }
  final next = List<HistoryEditMediaItem>.from(current.where((e) => e.isImage));
  for (final item in picked) {
    if (next.length >= _kMaxImages) break;
    if (item.isImage) next.add(item);
  }
  return next;
}
