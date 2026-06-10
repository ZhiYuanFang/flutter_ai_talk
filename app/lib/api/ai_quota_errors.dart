import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/widgets/app_glass_overlay.dart';
import 'ai_quota_codes.dart';
import 'api_exceptions.dart';

/// 处理 AI 额度/登录业务码：40302 弹框「本月额度已用完」；40301 引导登录。
/// 返回 true 表示已展示专用 UX，调用方勿再 Toast 通用错误。
Future<bool> handleAiQuotaBusinessCode(BuildContext context, int code) async {
  if (code == kAiCodeQuotaExhausted) {
    await showGlassConfirmDialog(
      context,
      title: '提示',
      message: '本月额度已用完',
      confirmLabel: '知道了',
    );
    return true;
  }
  if (code == kAiCodeNotLoggedIn) {
    final go = await showGlassConfirmDialog(
          context,
          title: '需要登录',
          message: '请先登录账号',
          confirmLabel: '去登录',
        ) ??
        false;
    if (go && context.mounted) {
      await context.push('/login');
    }
    return true;
  }
  return false;
}

/// [ApiBusinessException] 便捷封装。
Future<bool> handleAiQuotaException(BuildContext context, ApiBusinessException e) =>
    handleAiQuotaBusinessCode(context, e.code);
