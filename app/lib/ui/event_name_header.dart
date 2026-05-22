import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import 'event_logo.dart';

/// 历史详情等页面：事件名 + logo + 品牌色。
class EventNameHeader extends StatelessWidget {
  const EventNameHeader({
    super.key,
    required this.name,
    this.event,
    this.logoSize = 28,
  });

  final String name;
  final EventDefinition? event;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, event);
    return Row(
      children: [
        EventLogo(definition: event, size: logoSize),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
          ),
        ),
      ],
    );
  }
}
