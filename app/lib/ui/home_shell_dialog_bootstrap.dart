import 'package:flutter/material.dart';

import '../data/notify_banner_repository.dart';
import '../data/repositories.dart' show VersionRepository, readPackageVersion;
import 'notify_banner_prompt.dart';
import 'version_prompt.dart';

/// 主壳启动级弹窗编排：先 notify，再 version（游客与已登录均检查 version）。
///
/// 调用方（[UcgHomeShell]）须在同挂载周期内 single-flight，且不得挂在 resume / 登录中途。
Future<void> runHomeShellDialogBootstrap({
  required BuildContext context,
  required VersionRepository versionRepo,
}) async {
  // 维护/公告优先；失败静默，不阻塞后续 version
  try {
    await maybeShowNotifyBannerPrompt(
      context: context,
      repo: const NotifyBannerRepository(),
    );
  } catch (_) {}
  if (!context.mounted) return;

  // 游客与已登录均自动检查；无鉴权
  try {
    final currentVersion = await readPackageVersion();
    if (!context.mounted) return;
    await maybeShowVersionPrompt(
      context: context,
      repo: versionRepo,
      currentVersion: currentVersion,
    );
  } catch (_) {}
}
