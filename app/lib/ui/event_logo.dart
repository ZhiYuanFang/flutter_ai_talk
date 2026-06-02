import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/event_definition.dart';

const kEventPlaceholderAsset = 'assets/images/event_placeholder.png';

/// 事件 logo：本地文件 → 网络（Web）→ 占位图。
class EventLogo extends StatelessWidget {
  const EventLogo({
    super.key,
    required this.definition,
    this.size = 18,
    this.borderRadius,
  });

  final EventDefinition? definition;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 4);
    final local = definition?.localLogoPath;
    if (!kIsWeb && local != null && local.isNotEmpty) {
      final file = File(local);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(size, radius),
          ),
        );
      }
    }
    if (kIsWeb) {
      final url = definition?.logoUrl;
      if (url != null && url.isNotEmpty) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(size, radius),
          ),
        );
      }
    }
    return _placeholder(size, radius);
  }

  Widget _placeholder(double size, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        kEventPlaceholderAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.event, size: size * 0.75),
        ),
      ),
    );
  }
}
