import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// UCG CDN / 远程图片：Web 用 HTML `<img>` 规避跨域 fetch（statusCode 0），移动端走默认字节流。
///
/// 勿用于 [CircleAvatar.backgroundImage]——Decoration 路径在 Web 仍会触发 Same-Origin 解码错误；
/// 圆形头像请用 [UcgAvatar]。
ImageProvider ucgNetworkImageProvider(String url) {
  return NetworkImage(
    url,
    webHtmlElementStrategy:
        kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
  );
}

/// 圆形头像：ClipOval + [UcgNetworkImage]，规避 Web 上 CircleAvatar/DecorationImage 的 CORS 限制。
class UcgAvatar extends StatelessWidget {
  const UcgAvatar({
    super.key,
    this.url,
    required this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.placeholderIcon = Icons.person_rounded,
    this.placeholderIconSize,
  });

  final String? url;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData placeholderIcon;
  final double? placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary.withValues(alpha: 0.12);
    final fg = foregroundColor ?? scheme.primary;
    final iconSize = placeholderIconSize ?? radius + 2;
    final hasUrl = url != null && url!.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? UcgNetworkImage(
                url: url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(bg, fg, iconSize),
              )
            : _placeholder(bg, fg, iconSize),
      ),
    );
  }

  Widget _placeholder(Color bg, Color fg, double iconSize) {
    return ColoredBox(
      color: bg,
      child: Center(child: Icon(placeholderIcon, size: iconSize, color: fg)),
    );
  }
}

/// 与 [Image.network] 同参，Web 自动启用 [WebHtmlElementStrategy.prefer]。
class UcgNetworkImage extends StatelessWidget {
  const UcgNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
    );
  }
}
