import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../data/history_edit_media_item.dart';
import '../../data/ucg_album_picker.dart';
import '../../data/ucg_compose_initial_media.dart';
import '../../data/ucg_media_picker.dart';
import '../../data/ucg_repository.dart';
import '../../../ui/widgets/app_glass_overlay.dart';
import 'ucg_compose_light_glass_panel.dart';
import '../ucg_album_picker_screen.dart';

export '../../data/ucg_compose_initial_media.dart';

enum _UcgComposeEntryPick { camera, gallery }

/// 微信式发布入口：玻璃 sheet → 拍摄 / 自建相册 → 本地媒体 → compose 后台上传。
Future<UcgComposeInitialMedia?> showUcgComposeEntrySheet(
  BuildContext context, {
  required UcgRepository repo,
}) async {
  final pick = await showGlassAdaptiveBottomSheet<_UcgComposeEntryPick>(
    context: context,
    maxHeightFraction: 0.35,
    scrollable: false,
    useLightGlass: true,
    glassContentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
    bodyBuilder: (ctx) => _EntrySheetBody(showCamera: !kIsWeb),
  );
  if (pick == null || !context.mounted) return null;

  if (pick == _UcgComposeEntryPick.camera) {
    return showUcgCameraCaptureSheet(context);
  }

  if (kIsWeb) {
    try {
      return await ucgPickMediaWebLocalFallback();
    } on UcgAlbumMixedMediaException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不能同时选择图片和视频')),
        );
      }
      return null;
    }
  }

  final items = await Navigator.of(context).push<List<HistoryEditMediaItem>>(
    MaterialPageRoute(
      builder: (_) => UcgAlbumPickerScreen(repo: repo, deferUpload: true),
    ),
  );
  if (items == null || items.isEmpty) return null;
  return UcgComposeInitialMedia.fromHistoryItems(items);
}

class _EntrySheetBody extends StatelessWidget {
  const _EntrySheetBody({required this.showCamera});

  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    final textColor = ucgComposeLightTextColor(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCamera)
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: textColor),
            title: Text('拍摄', style: TextStyle(color: textColor)),
            onTap: () => Navigator.pop(context, _UcgComposeEntryPick.camera),
          ),
        ListTile(
          leading: Icon(Icons.photo_library_outlined, color: textColor),
          title: Text('从手机相册选择', style: TextStyle(color: textColor)),
          onTap: () => Navigator.pop(context, _UcgComposeEntryPick.gallery),
        ),
      ],
    );
  }
}

/// 拍摄子选项（拍照 / 录像）— 返回本地 path。
Future<UcgComposeInitialMedia?> showUcgCameraCaptureSheet(BuildContext context) async {
  if (kIsWeb) return null;
  final isVideo = await showGlassAdaptiveBottomSheet<bool>(
    context: context,
    maxHeightFraction: 0.32,
    scrollable: false,
    useLightGlass: true,
    glassContentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
    bodyBuilder: (ctx) {
      final textColor = ucgComposeLightTextColor(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: textColor),
            title: Text('拍照', style: TextStyle(color: textColor)),
            onTap: () => Navigator.pop(ctx, false),
          ),
          ListTile(
            leading: Icon(Icons.videocam_outlined, color: textColor),
            title: Text('录像', style: TextStyle(color: textColor)),
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      );
    },
  );
  if (isVideo == null || !context.mounted) return null;
  if (isVideo) {
    final path = await ucgCaptureVideoLocalPath();
    if (path == null || !context.mounted) return null;
    return UcgComposeInitialMedia(videoLocalPath: path);
  }
  final path = await ucgCapturePhotoLocalPath();
  if (path == null || !context.mounted) return null;
  return UcgComposeInitialMedia(imageLocalPaths: [path]);
}

/// compose 页内追加图片：原生 deferUpload，Web 本地选择。
Future<UcgComposeInitialMedia?> ucgPickMoreImagesForCompose(
  BuildContext context, {
  required UcgRepository repo,
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) return null;
  if (kIsWeb) {
    try {
      return await ucgPickMediaWebLocalFallback(maxImages: remainingSlots);
    } on UcgAlbumMixedMediaException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不能同时选择图片和视频')),
        );
      }
      return null;
    }
  }
  final items = await Navigator.of(context).push<List<HistoryEditMediaItem>>(
    MaterialPageRoute(
      builder: (_) => UcgAlbumPickerScreen(
        repo: repo,
        maxPhotos: remainingSlots,
        deferUpload: true,
      ),
    ),
  );
  if (items == null || items.isEmpty) return null;
  return UcgComposeInitialMedia.fromHistoryItems(items);
}
