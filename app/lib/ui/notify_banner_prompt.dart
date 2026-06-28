import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/notify_banner_dismiss_store.dart';
import '../data/notify_banner_repository.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 主页进入后拉取 notify banner；维护强阻断优先于版本弹窗。
Future<void> maybeShowNotifyBannerPrompt({
  required BuildContext context,
  required NotifyBannerRepository repo,
}) async {
  NotifyBanner? banner;
  try {
    banner = await repo.fetchBanner();
  } catch (_) {
    return;
  }
  if (!context.mounted || banner == null) return;

  if (banner.dismissible) {
    final dismissed = await NotifyBannerDismissStore.isDismissed(banner.contentKey);
    if (dismissed) return;
  }

  if (!context.mounted) return;
  await _showNotifyBannerDialog(context: context, initial: banner);
}

Future<void> _showNotifyBannerDialog({
  required BuildContext context,
  required NotifyBanner initial,
}) {
  if (initial.dismissible) {
    return showGlassDialog<void>(
      context: context,
      barrierDismissible: true,
      contentBuilder: (ctx) => _DismissibleBannerBody(
        banner: initial,
        onClose: (neverAgain) async {
          if (neverAgain) {
            await NotifyBannerDismissStore.saveDismissed(initial.contentKey);
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  return showGlassDialog<void>(
    context: context,
    barrierDismissible: false,
    contentBuilder: (ctx) => PopScope(
      canPop: false,
      child: _BlockingBannerBody(banner: initial),
    ),
  );
}

class _DismissibleBannerBody extends StatefulWidget {
  const _DismissibleBannerBody({required this.banner, required this.onClose});

  final NotifyBanner banner;
  final Future<void> Function(bool neverAgain) onClose;

  @override
  State<_DismissibleBannerBody> createState() => _DismissibleBannerBodyState();
}

class _DismissibleBannerBodyState extends State<_DismissibleBannerBody> {
  var _neverAgain = false;

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.banner.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: glassText),
        ),
        const SizedBox(height: 12),
        Text(
          widget.banner.message,
          style: TextStyle(fontSize: 14, height: 1.45, color: glassLabel),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _neverAgain,
          onChanged: (v) => setState(() => _neverAgain = v ?? false),
          title: Text('不再提示', style: TextStyle(color: glassLabel, fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () => widget.onClose(_neverAgain),
              style: TextButton.styleFrom(foregroundColor: glassLabel),
              child: const Text('关闭'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => widget.onClose(_neverAgain),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              child: const Text('知道了'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockingBannerBody extends StatelessWidget {
  const _BlockingBannerBody({required this.banner});

  final NotifyBanner banner;

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          banner.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: glassText),
        ),
        const SizedBox(height: 12),
        Text(
          banner.message,
          style: TextStyle(fontSize: 14, height: 1.45, color: glassLabel),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.center,
          child: FilledButton(
            onPressed: SystemNavigator.pop,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: const StadiumBorder(),
            ),
            child: const Text('退出'),
          ),
        ),
      ],
    );
  }
}
