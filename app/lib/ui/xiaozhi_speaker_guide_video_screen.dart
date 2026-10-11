import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../api/app_debug_log.dart';

/// 小智引导视频全屏播放（入参 title + videoCdnUrl）。
class XiaozhiSpeakerGuideVideoScreen extends StatefulWidget {
  const XiaozhiSpeakerGuideVideoScreen({
    super.key,
    required this.title,
    required this.videoCdnUrl,
  });

  final String title;
  final String videoCdnUrl;

  @override
  State<XiaozhiSpeakerGuideVideoScreen> createState() =>
      _XiaozhiSpeakerGuideVideoScreenState();
}

class _XiaozhiSpeakerGuideVideoScreenState
    extends State<XiaozhiSpeakerGuideVideoScreen> {
  VideoPlayerController? _controller;
  var _initializing = true;
  String? _error;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initPlayer());
  }

  Future<void> _initPlayer() async {
    final url = widget.videoCdnUrl.trim();
    if (url.isEmpty) {
      if (!_disposed && mounted) {
        setState(() {
          _initializing = false;
          _error = '视频地址无效';
        });
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      AppDebugLog.xiaozhiGuide('play invalid url');
      if (!_disposed && mounted) {
        setState(() {
          _initializing = false;
          _error = '视频地址无效';
        });
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.play();
      if (!_disposed && mounted) {
        setState(() {
          _controller = controller;
          _initializing = false;
          _error = null;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      AppDebugLog.xiaozhiGuide('play init err=$e');
      await controller.dispose();
      if (!_disposed && mounted) {
        setState(() {
          _initializing = false;
          _error = '视频加载失败，请稍后重试';
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      unawaited(c.pause());
    } else {
      unawaited(c.play());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.title.trim().isEmpty ? '引导视频' : widget.title.trim();
    final c = _controller;
    final ready = c != null && c.value.isInitialized && _error == null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _initializing
              ? const CircularProgressIndicator(color: Colors.white)
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('返回'),
                          ),
                        ],
                      ),
                    )
                  : ready
                      ? ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: c,
                          builder: (context, value, _) {
                            return GestureDetector(
                              onTap: _togglePlay,
                              child: AspectRatio(
                                aspectRatio: value.aspectRatio == 0
                                    ? 16 / 9
                                    : value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(c),
                                    if (!value.isPlaying)
                                      const Icon(
                                        Icons.play_circle_outline,
                                        size: 64,
                                        color: Colors.white70,
                                      ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: VideoProgressIndicator(
                                        c,
                                        allowScrubbing: true,
                                        colors: const VideoProgressColors(
                                          playedColor: Colors.white,
                                          bufferedColor: Colors.white38,
                                          backgroundColor: Colors.white24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
