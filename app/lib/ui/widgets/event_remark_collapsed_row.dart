import 'package:flutter/material.dart';

/// 备注折叠行：空则仅「编辑备注」；非空则 `{文案}` +「编辑备注」+ 编辑图标。
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
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasRemark) ...[
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
            ],
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
            if (!hasRemark) const Spacer(),
          ],
        ),
      ),
    );
  }
}
