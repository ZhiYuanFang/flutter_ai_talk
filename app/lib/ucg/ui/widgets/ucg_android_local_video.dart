import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _localVideoChannel = MethodChannel('com.fzy.pangbao/local_video');
const _localVideoEvents = EventChannel('com.fzy.pangbao/local_video/events');

bool ucgUseAndroidNativeLocalVideo({
  String? videoUrl,
  String? filePath,
  String? contentUri,
}) {
  if (kIsWeb || !Platform.isAndroid) return false;
  if (videoUrl != null && videoUrl.isNotEmpty) return false;
  return (filePath != null && filePath.isNotEmpty) ||
      (contentUri != null && contentUri.isNotEmpty);
}

Future<bool> ucgOpenSystemVideoPlayer({
  String? filePath,
  String? contentUri,
}) async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    await _localVideoChannel.invokeMethod<void>('openSystemPlayer', {
      'filePath': filePath,
      'contentUri': contentUri,
    });
    return true;
  } catch (_) {
    return false;
  }
}

/// Android 本地视频：原生 [VideoView]（MediaPlayer），规避 ExoPlayer 在海思上的硬解失败。
class UcgAndroidLocalVideoView extends StatefulWidget {
  const UcgAndroidLocalVideoView({
    super.key,
    this.filePath,
    this.contentUri,
    this.onReady,
    this.onFailed,
  });

  final String? filePath;
  final String? contentUri;
  final VoidCallback? onReady;
  final VoidCallback? onFailed;

  @override
  State<UcgAndroidLocalVideoView> createState() => _UcgAndroidLocalVideoViewState();
}

class _UcgAndroidLocalVideoViewState extends State<UcgAndroidLocalVideoView> {
  StreamSubscription<dynamic>? _events;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _events = _localVideoEvents.receiveBroadcastStream().listen(
      (event) {
        if (event is Map && event['event'] == 'prepared') {
          widget.onReady?.call();
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _failed = true);
        widget.onFailed?.call();
      },
    );
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return AndroidView(
      viewType: 'ucg-local-video',
      layoutDirection: TextDirection.ltr,
      creationParams: <String, String?>{
        'filePath': widget.filePath,
        'contentUri': widget.contentUri,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
