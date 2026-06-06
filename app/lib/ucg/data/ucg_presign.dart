import 'ucg_media_url.dart';

/// `POST /ucg/app/api/media/presign` 请求/响应契约（对齐 go_ai_talk ucg-service）。
class UcgPresignRequest {
  const UcgPresignRequest({
    required this.mediaKind,
    required this.extension,
  });

  /// 1=图片，2=视频。
  final int mediaKind;
  final String extension;

  Map<String, dynamic> toJson() => {
        'mediaKind': mediaKind,
        'extension': extension,
      };

  factory UcgPresignRequest.fromFileName(String fileName, {required bool isVideo}) {
    return UcgPresignRequest(
      mediaKind: isVideo ? 2 : 1,
      extension: ucgExtensionFromFileName(fileName, isVideo: isVideo),
    );
  }
}

/// 上传完成后的 objectKey + 可选 API cdnUrl（展示用）。
class UcgUploadResult {
  const UcgUploadResult({required this.objectKey, this.cdnUrl});

  final String objectKey;
  final String? cdnUrl;

  String get displayUrl => UcgMediaUrl.resolveUrl(objectKey: objectKey, cdnUrl: cdnUrl);
}

class UcgPresignResult {
  const UcgPresignResult({
    required this.objectKey,
    required this.uploadUrl,
    this.cdnUrl,
    this.headers = const {},
  });

  final String objectKey;
  final String uploadUrl;
  final String? cdnUrl;
  final Map<String, String> headers;

  factory UcgPresignResult.fromJson(Map<String, dynamic> json) {
    final objectKey = json['objectKey'] as String? ?? json['key'] as String? ?? '';
    final uploadUrl = json['uploadUrl'] as String? ?? json['url'] as String? ?? '';
    if (objectKey.isEmpty || uploadUrl.isEmpty) {
      throw const FormatException('presign 响应缺少 objectKey 或 uploadUrl');
    }
    final headersRaw = json['headers'];
    final headers = <String, String>{};
    if (headersRaw is Map) {
      headersRaw.forEach((k, v) {
        if (k != null && v != null) headers[k.toString()] = v.toString();
      });
    }
    return UcgPresignResult(
      objectKey: objectKey,
      uploadUrl: uploadUrl,
      cdnUrl: json['cdnUrl'] as String?,
      headers: headers,
    );
  }
}

String ucgExtensionFromFileName(String fileName, {required bool isVideo}) {
  final lower = fileName.toLowerCase();
  final dot = lower.lastIndexOf('.');
  var ext = dot >= 0 ? lower.substring(dot + 1) : (isVideo ? 'mp4' : 'jpg');
  if (ext == 'jpeg') ext = 'jpg';
  if (ext == 'mpeg') ext = 'mp4';
  return ext;
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
