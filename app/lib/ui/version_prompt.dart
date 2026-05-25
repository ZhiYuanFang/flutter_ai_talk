import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/gateway_absolute_url.dart';
import '../config/env.dart';
import '../data/repositories.dart';
import '../update/apk_update.dart';
import '../util/reload.dart';
import 'widgets/app_toast.dart';

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
          TextButton(onPressed: reloadPage, child: const Text('刷新')),
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('发现新版本'),
        content: Text('当前：$currentVersion\n最新：${info.latestVersion}\n\n${info.releaseNotes}'),
        actions: [
          if (!info.forceUpdate) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后')),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse('https://apps.apple.com/app/id${AppEnv.iosAppStoreId}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('前往 App Store'),
            ),
          if (defaultTargetPlatform == TargetPlatform.android)
            FilledButton(
              onPressed: () async {
                final url = resolveGatewayAbsoluteUrl(info.androidApkUrl) ?? info.androidApkUrl.trim();
                if (url.isEmpty) {
                  if (ctx.mounted) {
                    showAppToast('暂无安装包下载地址', tone: AppToastTone.error);
                  }
                  return;
                }
                final uri = Uri.tryParse(url);
                if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
                  if (ctx.mounted) {
                    showAppToast('下载地址无效', tone: AppToastTone.error);
                  }
                  return;
                }
                Navigator.pop(ctx);
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dCtx) => _ApkDownloadProgressDialog(downloadUrl: url),
                );
              },
              child: const Text('下载并安装'),
            ),
        ],
      );
    },
  );
}

class _ApkDownloadProgressDialog extends StatefulWidget {
  const _ApkDownloadProgressDialog({required this.downloadUrl});

  final String downloadUrl;

  @override
  State<_ApkDownloadProgressDialog> createState() => _ApkDownloadProgressDialogState();
}

class _ApkDownloadProgressDialogState extends State<_ApkDownloadProgressDialog> {
  double? _fraction;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await downloadAndInstallApkFromUrl(
        widget.downloadUrl,
        onProgress: (f) {
          if (mounted) setState(() => _fraction = f);
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在下载更新'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error == null) ...[
              if (_fraction != null)
                LinearProgressIndicator(value: _fraction!.clamp(0.0, 1.0))
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                _fraction != null ? '${(_fraction! * 100).clamp(0, 100).toStringAsFixed(0)}%' : '准备中…',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        if (_error != null) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭')),
      ],
    );
  }
}
