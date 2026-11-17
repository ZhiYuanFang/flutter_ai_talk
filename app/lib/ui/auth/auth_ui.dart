import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// 登录/注册品牌头：圆标 +「胖宝」+ 副文案，色经 [AppColor] 随主题。
Widget buildAuthBrandHeader(BuildContext context) {
  final primary = AppColor.primary(context);
  final surface = AppColor.surface(context);
  final onShell = AppColor.textPrimary(context);
  final muted = AppColor.textMuted(context);
  // 圆标底：surface 上叠一点 primary，避免夜空/浅壳硬编码奶油蓝
  final logoFill = Color.alphaBlend(primary.withValues(alpha: 0.12), surface);
  return Column(
    children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: logoFill,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: onShell.withValues(alpha: 0.12),
              offset: const Offset(8, 8),
              blurRadius: 16,
            ),
            BoxShadow(
              color: AppColor.pageBg(context).withValues(alpha: 0.55),
              offset: const Offset(-8, -8),
              blurRadius: 16,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_icon_round.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.expand(),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        '胖宝',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onShell,
              letterSpacing: 4,
            ),
      ),
      const SizedBox(height: 8),
      Text(
        '记录宝宝成长的每一步',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: muted),
      ),
    ],
  );
}

InputDecoration buildAuthInputDecoration({
  required String labelText,
  String? hintText,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    suffixIcon: suffixIcon,
  );
}

Widget buildAuthPrivacyAgreement(
  BuildContext context, {
  required String leadText,
  required VoidCallback onTapUserAgreement,
  required VoidCallback onTapPrivacyPolicy,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTapUserAgreement,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColor.textMuted(context)),
            children: [
              TextSpan(text: '$leadText '),
              TextSpan(
                text: '用户协议',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: onTapPrivacyPolicy,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColor.textMuted(context)),
            children: [
              const TextSpan(text: '和 '),
              TextSpan(
                text: '隐私政策',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
