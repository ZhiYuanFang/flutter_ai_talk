import 'package:flutter/material.dart';

/// 备注折叠行：空则仅「编辑备注」居中；非空则 `{文案}` +「编辑备注」+ 编辑图标。
class EventRemarkCollapsedRow extends StatelessWidget {
  const EventRemarkCollapsedRow({
    super.key,
    required this.remarkText,
    required this.onEdit,
    required this.textColor,
    required this.accentColor,
  });

  final String remarkText;
  final VoidCallback onEdit;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final trimmed = remarkText.trim();
    final hasRemark = trimmed.isNotEmpty;
    // 编辑入口（文案 + 图标）
    final editAffordance = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '编辑备注',
          style: TextStyle(
            fontSize: 14,
            height: 1.25,
            color: accentColor,
            decoration: TextDecoration.underline,
            decorationColor: accentColor,
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.edit_outlined,
          size: 16,
          color: accentColor,
        ),
      ],
    );

    // 空态：拉满宽 + Center（避免 InkWell 收窄导致看起来仍偏左）
    if (!hasRemark) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(child: editAffordance),
          ),
        ),
      );
    }

    // 有备注：左正文 + 右编辑
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                trimmed,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            editAffordance,
          ],
        ),
      ),
    );
  }
}
