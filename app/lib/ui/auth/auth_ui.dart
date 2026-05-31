import 'package:flutter/material.dart';

const kAuthHintColor = Color(0xFF8C7E74);

Widget buildAuthBrandHeader(BuildContext context, {Color hintColor = kAuthHintColor}) {
  return Column(
    children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1F9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(8, 8),
              blurRadius: 16,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              offset: const Offset(-8, -8),
              blurRadius: 16,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_icon.png',
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
              color: const Color(0xFF4A3428),
              letterSpacing: 4,
            ),
      ),
      const SizedBox(height: 8),
      Text(
        '记录宝宝成长的每一步',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: hintColor),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            children: [
              TextSpan(text: '$leadText '),
              TextSpan(
                text: '用户协议',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            children: [
              const TextSpan(text: '和 '),
              TextSpan(
                text: '隐私政策',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
