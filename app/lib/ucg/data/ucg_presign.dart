/// `POST /ucg/app/api/media/presign` 请求/响应契约（与 OpenSpec ucg-media-cdn 一致）。
class UcgPresignRequest {
  const UcgPresignRequest({
    required this.fileName,
    required this.contentType,
  });

  final String fileName;
  final String contentType;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'contentType': contentType,
      };
}

class UcgPresignResult {
  const UcgPresignResult({
    required this.objectKey,
    required this.uploadUrl,
  });

  final String objectKey;
  final String uploadUrl;

  factory UcgPresignResult.fromJson(Map<String, dynamic> json) {
    final objectKey = json['objectKey'] as String? ?? json['key'] as String? ?? '';
    final uploadUrl = json['uploadUrl'] as String? ?? json['url'] as String? ?? '';
    if (objectKey.isEmpty || uploadUrl.isEmpty) {
      throw const FormatException('presign 响应缺少 objectKey 或 uploadUrl');
    }
    return UcgPresignResult(objectKey: objectKey, uploadUrl: uploadUrl);
  }
}

String ucgContentTypeForFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  return 'image/jpeg';
}

String ucgFallbackFileName({required bool isVideo, required String? path}) {
  if (path != null && path.isNotEmpty) {
    final parts = path.split(RegExp(r'[/\\]'));
    final name = parts.last;
    if (name.isNotEmpty) return name;
  }
  return isVideo ? 'video.mp4' : 'photo.jpg';
}
