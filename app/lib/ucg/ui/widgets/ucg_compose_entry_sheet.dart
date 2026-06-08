import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/ucg_album_picker.dart';
import '../../data/ucg_compose_initial_media.dart';
import '../../data/ucg_media_picker.dart';
import '../../data/ucg_repository.dart';
import '../../../ui/widgets/app_glass_overlay.dart';
import 'ucg_compose_light_glass_panel.dart';
import '../ucg_album_picker_screen.dart';

export '../../data/ucg_compose_initial_media.dart';

enum _UcgComposeEntryPick { camera, gallery }

/// 微信式发布入口：玻璃 sheet → 拍摄 / 自建相册 → 上传 → 返回预填媒体。
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
    return showUcgCameraCaptureSheet(context, repo: repo);
  }

  if (kIsWeb) {
    try {
      return await ucgPickMediaWebFallback(repo: repo);
    } on UcgAlbumMixedMediaException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不能同时选择图片和视频')),
        );
      }
      return null;
    }
  }

  return Navigator.of(context).push<UcgComposeInitialMedia>(
    MaterialPageRoute(builder: (_) => UcgAlbumPickerScreen(repo: repo)),
  );
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

/// 拍摄子选项（拍照 / 录像）— 玻璃 sheet。
Future<UcgComposeInitialMedia?> showUcgCameraCaptureSheet(
  BuildContext context, {
  required UcgRepository repo,
}) async {
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
    final upload = await ucgCaptureAndUploadVideo(repo: repo);
    if (upload == null || !context.mounted) return null;
    return UcgComposeInitialMedia(videoKey: upload.objectKey);
  }
  final upload = await ucgCaptureAndUploadPhoto(repo: repo);
  if (upload == null || !context.mounted) return null;
  return UcgComposeInitialMedia(imageKeys: [upload.objectKey]);
}

/// compose 页内追加图片：原生走自建相册，Web 降级。
Future<UcgComposeInitialMedia?> ucgPickMoreImagesForCompose(
  BuildContext context, {
  required UcgRepository repo,
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) return null;
  if (kIsWeb) {
    try {
      return await ucgPickMediaWebFallback(repo: repo, maxImages: remainingSlots);
    } on UcgAlbumMixedMediaException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不能同时选择图片和视频')),
        );
      }
      return null;
    }
  }
  return Navigator.of(context).push<UcgComposeInitialMedia>(
    MaterialPageRoute(
      builder: (_) => UcgAlbumPickerScreen(repo: repo, maxPhotos: remainingSlots),
    ),
  );
}
