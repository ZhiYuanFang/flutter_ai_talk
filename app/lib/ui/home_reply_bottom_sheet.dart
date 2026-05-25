import 'package:flutter/material.dart';

import 'widgets/app_adaptive_bottom_sheet.dart';

/// 展示 [sendCommand] 返回的完整服务端回复。
Future<void> showHomeReplyBottomSheet(BuildContext context, String reply) {
  return showAppAdaptiveBottomSheet<void>(
    context: context,
    bodyBuilder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('服务端回复', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            SelectableText(
              reply,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    },
  );
}
