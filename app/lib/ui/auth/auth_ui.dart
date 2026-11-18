import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../widgets/app_glass_overlay.dart';

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

/// 登录/注册协议勾选：圆形；链接下划线；尽量单行。
/// 不与首启隐私同意同步（登录层另算《用户协议》+《隐私政策》）。
Widget buildAuthPrivacyAgreementCheckbox(
  BuildContext context, {
  required bool agreed,
  required ValueChanged<bool> onChanged,
  required VoidCallback onTapUserAgreement,
  required VoidCallback onTapPrivacyPolicy,
}) {
  return _AuthAgreementCheckboxRow(
    agreed: agreed,
    onChanged: onChanged,
    onTapUserAgreement: onTapUserAgreement,
    onTapPrivacyPolicy: onTapPrivacyPolicy,
  );
}

class _AuthAgreementCheckboxRow extends StatefulWidget {
  const _AuthAgreementCheckboxRow({
    required this.agreed,
    required this.onChanged,
    required this.onTapUserAgreement,
    required this.onTapPrivacyPolicy,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapUserAgreement;
  final VoidCallback onTapPrivacyPolicy;

  @override
  State<_AuthAgreementCheckboxRow> createState() =>
      _AuthAgreementCheckboxRowState();
}

class _AuthAgreementCheckboxRowState extends State<_AuthAgreementCheckboxRow> {
  late final TapGestureRecognizer _userTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _userTap = TapGestureRecognizer()..onTap = widget.onTapUserAgreement;
    _privacyTap = TapGestureRecognizer()..onTap = widget.onTapPrivacyPolicy;
  }

  @override
  void didUpdateWidget(covariant _AuthAgreementCheckboxRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _userTap.onTap = widget.onTapUserAgreement;
    _privacyTap.onTap = widget.onTapPrivacyPolicy;
  }

  @override
  void dispose() {
    _userTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColor.textMuted(context);
    final primary = Theme.of(context).colorScheme.primary;
    final baseStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: muted);
    final linkStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: primary,
    );

    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: widget.agreed,
            // 圆形勾选，非默认方框。
            shape: const CircleBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => widget.onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                const TextSpan(text: '我已阅读并同意'),
                TextSpan(
                  text: '《用户协议》',
                  style: linkStyle,
                  recognizer: _userTap,
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '《隐私政策》',
                  style: linkStyle,
                  recognizer: _privacyTap,
                ),
              ],
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 未勾选时弹确认；确认则 [onAgreed] 并返回 true，取消返回 false。
Future<bool> ensureAuthAgreementOrConfirm(
  BuildContext context, {
  required bool agreed,
  required VoidCallback onAgreed,
}) async {
  if (agreed) return true;
  final ok = await showGlassConfirmDialog(
        context,
        title: '请同意协议',
        message: '登录/注册前需阅读并同意《用户协议》和《隐私政策》。是否同意？',
        cancelLabel: '取消',
        confirmLabel: '同意',
      ) ??
      false;
  if (!ok) return false;
  onAgreed();
  return true;
}

/// 社交登录：图标在上、底注小字；横向并排由调用方组 Row。
Widget buildAuthSocialIconButton({
  required Widget icon,
  required String label,
  required VoidCallback? onPressed,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 44, height: 44, child: icon),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

/// 微信官方圆标资源。
const kWeChatLoginIconAsset = 'assets/images/wx.png';

/// Apple 登录圆标（系统图标）。
Widget buildAppleLoginIcon({double size = 44}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.black,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Icon(Icons.apple, color: Colors.white, size: size * 0.72),
  );
}

/// 微信登录圆标（assets）。
Widget buildWeChatLoginIcon({double size = 44}) {
  return ClipOval(
    child: Image.asset(
      kWeChatLoginIconAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    ),
  );
}
