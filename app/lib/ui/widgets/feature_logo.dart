import 'package:flutter/material.dart';

/// 功能开通 Logo：网络 CDN → 占位图标。
///
/// 业务：catalog 下发 logo URL；未配置时用圆形图标占位，避免标题错位。
class FeatureLogo extends StatelessWidget {
  const FeatureLogo({
    super.key,
    required this.logoUrl,
    this.size = 28,
    this.accent,
  });

  final String logoUrl;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 4);
    final url = logoUrl.trim();
    if (url.isNotEmpty && url.startsWith('http')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context, radius),
          webHtmlElementStrategy: WebHtmlElementStrategy.never,
        ),
      );
    }
    return _placeholder(context, radius);
  }

  Widget _placeholder(BuildContext context, BorderRadius radius) {
    final scheme = Theme.of(context).colorScheme;
    final fg = accent ?? scheme.primary;
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: fg.withValues(alpha: 0.12),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.55,
            color: fg.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
