import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluwx/fluwx.dart';

import '../../api/app_debug_log.dart';
import '../../config/env.dart';
import '../../theme/app_color.dart';
import '../data/ucg_media_url.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'widgets/ucg_debate_vs_bar.dart';
import 'widgets/ucg_feed_fake_glass_panel.dart';
import 'widgets/ucg_mention_text.dart';

/// 离屏辩论分享布局：假玻璃卡 + 话题 + VS 条 + 前几条论点摘要。
class UcgDebateShareLayout extends StatelessWidget {
  const UcgDebateShareLayout({
    super.key,
    required this.post,
    this.argumentSnippets = const [],
  });

  final UcgPost post;
  final List<String> argumentSnippets;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final fg = ucgFeedFakeGlassTextColor(context);
    // 分享离屏底与假玻璃同族，避免近白 contentCard
    final backdrop = AppColor.panelGlassBottom(context);

    return ColoredBox(
      color: backdrop,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: UcgFeedFakeGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (post.text.isNotEmpty)
                  Text(
                    post.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: fg.withValues(alpha: 0.92),
                    ),
                  ),
                const SizedBox(height: 12),
                UcgDebateVsBar(
                  leftLabel: post.debateLeft,
                  rightLabel: post.debateRight,
                  leftRatio: post.debateLeftRatio,
                  rightRatio: post.debateRightRatio,
                  totalVotes: post.leftVoteCount + post.rightVoteCount,
                  myVoteSide: post.myVoteSide,
                  interactive: false,
                ),
                if (argumentSnippets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final snippet in argumentSnippets.take(3)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: ucgFeedFakeGlassArgumentPillColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColor.divider(context)),
                      ),
                      child: Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: fg.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> captureDebateSharePng(
  BuildContext context, {
  required UcgPost post,
  List<UcgComment> comments = const [],
}) async {
  final snippets = comments
      .take(3)
      .map((c) {
        final nick = c.authorNickname.isEmpty ? '用户' : c.authorNickname;
        final body = UcgMentionText.displayComment(c.text);
        return '$nick：$body';
      })
      .toList();

  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -UcgDebateShareLayout.width * 2,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: UcgDebateShareLayout(post: post, argumentSnippets: snippets),
      ),
    ),
  );
  overlay.insert(entry);
  await Future<void>.delayed(Duration.zero);
  await WidgetsBinding.instance.endOfFrame;

  Uint8List? png;
  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      png = byteData?.buffer.asUint8List();
    }
  } finally {
    entry.remove();
    entry.dispose();
  }
  return png;
}

Future<void> shareDebatePostToWeChat(
  BuildContext context,
  WidgetRef ref, {
  required UcgPost post,
  List<UcgComment> comments = const [],
  WeChatScene scene = WeChatScene.session,
}) async {
  if (AppEnv.wechatAppId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置微信分享')),
      );
    }
    return;
  }

  final fluwx = Fluwx();
  final universalLink = AppEnv.wechatUniversalLink.isEmpty ? null : AppEnv.wechatUniversalLink;
  final registered = await fluwx.registerApi(appId: AppEnv.wechatAppId, universalLink: universalLink);
  if (!registered) {
    AppDebugLog.ucgShare('registerApi failed');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('微信 SDK 未就绪')),
      );
    }
    return;
  }

  if (!await fluwx.isWeChatInstalled) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未安装微信')),
      );
    }
    return;
  }

  final title = post.text.trim().isEmpty ? '话题辩论' : post.text.trim();
  Uint8List? png;
  String? imageUrl;

  if (!context.mounted) return;
  try {
    png = await captureDebateSharePng(context, post: post, comments: comments);
    if (png != null && png.isNotEmpty) {
      final repo = ref.read(ucgRepositoryProvider);
      final presign = await repo.presignMedia(isVideo: false, fileName: 'debate_share.png');
      await repo.uploadToPresignedUrl(
        uploadUrl: presign.uploadUrl,
        bytes: png,
        contentType: 'image/png',
        extraHeaders: presign.headers,
      );
      imageUrl = presign.cdnUrl?.trim();
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = UcgMediaUrl.objectKeyToCdn(presign.objectKey);
      }
      AppDebugLog.ucgShare('upload ok imageUrl=$imageUrl bytes=${png.length}');
    }
  } catch (e) {
    AppDebugLog.ucgShare('upload fail err=$e');
  }

  try {
    if (png != null && png.isNotEmpty) {
      await fluwx.share(
        WeChatShareImageModel(
          WeChatImageToShare(uint8List: png),
          title: title,
          scene: scene,
        ),
      );
      return;
    }
    await fluwx.share(
      WeChatShareTextModel(title, title: title, scene: scene),
    );
  } catch (e) {
    AppDebugLog.ucgShare('share fail err=$e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分享失败')),
      );
    }
  }
}
