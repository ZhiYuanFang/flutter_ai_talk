import 'package:flutter/material.dart';

/// 展示 [sendCommand] 返回的完整服务端回复。
Future<void> showHomeReplyBottomSheet(BuildContext context, String reply) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewPaddingOf(ctx).bottom;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.55;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('服务端回复', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: SingleChildScrollView(
                child: SelectableText(
                  reply,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
