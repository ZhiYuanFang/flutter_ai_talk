import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// UCG CDN / 远程图片：Web 用 HTML `<img>` 规避跨域 fetch（statusCode 0），移动端走默认字节流。
ImageProvider ucgNetworkImageProvider(String url) {
  return NetworkImage(
    url,
    webHtmlElementStrategy:
        kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
  );
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
