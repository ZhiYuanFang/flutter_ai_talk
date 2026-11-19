import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../data/repositories.dart';
import '../util/reload.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

import '../theme/app_color.dart';

Future<void> maybeShowVersionPrompt({
  required BuildContext context,
  required VersionRepository repo,
  required String currentVersion,
}) async {
  final info = await repo.checkForUpdate(currentVersion);
  if (!context.mounted || info == null) return;

  if (kIsWeb) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!context.mounted || messenger == null) return;
    messenger.showMaterialBanner(
      MaterialBanner(
        content: const Text('新版本可用，请刷新页面'),
        actions: [
          const TextButton(onPressed: reloadPage, child: Text('刷新')),
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    return;
  }

  await showGlassDialog<void>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      // Android：引导官网；iOS：App Store。
      final androidGuide =
          '请前往官网下载安装最新版：\n${AppEnv.androidUpdateWebUrl}';
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '发现新版本',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前：$currentVersion\n最新：${info.latestVersion}\n\n${info.releaseNotes}'
            '${defaultTargetPlatform == TargetPlatform.android ? '\n\n$androidGuide' : ''}',
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (!info.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: glassLabel),
                  child: const Text('稍后'),
                ),
              const Spacer(),
              if (defaultTargetPlatform == TargetPlatform.iOS)
                FilledButton(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://apps.apple.com/cn/app/id${AppEnv.iosAppStoreId}',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor:
                        AppColor.onFill(context, scheme.primary),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('前往 App Store'),
                ),
              if (defaultTargetPlatform == TargetPlatform.android)
                FilledButton(
                  onPressed: () async {
                    final uri = Uri.parse(AppEnv.androidUpdateWebUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else if (ctx.mounted) {
                      showAppToast('无法打开官网，请稍后重试', tone: AppToastTone.error);
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor:
                        AppColor.onFill(context, scheme.primary),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('去更新'),
                ),
            ],
          ),
        ],
      );
    },
  );
}
