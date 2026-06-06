import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'ucg_presign.dart';
import 'ucg_repository.dart';

const maxUcgVideoBytes = 20 * 1024 * 1024;
const maxUcgVideoDuration = Duration(seconds: 15);

final _picker = ImagePicker();

bool ucgValidateVideoBytes(Uint8List bytes, {Duration? duration}) {
  if (bytes.length > maxUcgVideoBytes) return false;
  if (duration != null && duration > maxUcgVideoDuration) return false;
  return true;
}

Future<UcgUploadResult> ucgUploadBytes({
  required UcgRepository repo,
  required Uint8List bytes,
  required String fileName,
  required String contentType,
  required bool isVideo,
}) async {
  return repo.uploadMediaBytes(
    isVideo: isVideo,
    fileName: fileName,
    bytes: bytes,
    contentType: contentType,
  );
}

Future<List<UcgUploadResult>> ucgPickAndUploadImages({
  required UcgRepository repo,
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) return const [];
  final picked = await _picker.pickMultiImage(
    limit: remainingSlots,
    imageQuality: 85,
  );
  if (picked.isEmpty) return const [];

  final results = <UcgUploadResult>[];
  for (final file in picked) {
    final bytes = await file.readAsBytes();
    final name = ucgFallbackFileName(isVideo: false, path: file.path);
    final uploaded = await ucgUploadBytes(
      repo: repo,
      bytes: bytes,
      fileName: name,
      contentType: ucgContentTypeForFileName(name),
      isVideo: false,
    );
    results.add(uploaded);
  }
  return results;
}

Future<UcgUploadResult?> ucgPickAndUploadVideo({
  required UcgRepository repo,
}) async {
  final file = await _picker.pickVideo(
    source: ImageSource.gallery,
    maxDuration: maxUcgVideoDuration,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  if (!ucgValidateVideoBytes(bytes)) {
    throw StateError('视频超过 20MB 或 15 秒限制');
  }

  final name = ucgFallbackFileName(isVideo: true, path: file.path);
  return ucgUploadBytes(
    repo: repo,
    bytes: bytes,
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: true,
  );
}
