import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/widgets/app_glass_overlay.dart';
import 'ai_quota_codes.dart';
import 'api_exceptions.dart';

/// 处理 AI 额度/登录业务码：40301 引导登录。
/// 客户端先行去额度：40302 **不再**弹「本月额度已用完」框（返回 false 交由调用方通用错误）。
/// 返回 true 表示已展示专用 UX，调用方勿再 Toast 通用错误。
Future<bool> handleAiQuotaBusinessCode(BuildContext context, int code) async {
  // 40302：客户端不做额度限制 UX
  if (code == kAiCodeQuotaExhausted) {
    return false;
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
