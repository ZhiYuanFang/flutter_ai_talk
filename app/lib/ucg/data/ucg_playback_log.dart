import 'package:video_player/video_player.dart';

/// CDN 播放日志用 URL 摘要（host + key 末段，不含 query）。
String ucgPlayLogUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return 'url=invalid';
  final host = uri.host.isNotEmpty ? uri.host : uri.scheme;
  final path = uri.path.isNotEmpty ? uri.path : '/';
  final query = uri.query.isNotEmpty ? ' query=${uri.query}' : '';
  final segments = uri.pathSegments;
  final key = segments.isNotEmpty ? segments.last : uri.path;
  return 'host=$host path=$path$query key=$key';
}

String ucgPlayTruncate(String text, {int max = 400}) {
  if (text.length <= max) return text;
  return '${text.substring(0, max)}…';
}

String ucgPlayErrorMessage(Object? error, [VideoPlayerController? controller]) {
  final desc = controller?.value.errorDescription;
  if (desc != null && desc.isNotEmpty) return ucgPlayTruncate(desc);
  if (error != null) return ucgPlayTruncate(error.toString());
  return 'unknown';
}
