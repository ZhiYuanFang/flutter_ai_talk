import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// 分析进行中的状态条：与思考流正文分开，避免被看成同一段字。
class AnalysisWaitCallout extends StatelessWidget {
  const AnalysisWaitCallout({super.key, required this.accent});

  /// 当前功能色，用于色条与图标。
  final Color accent;

  static const _title = '正在为宝宝分析，会比较久';
  static const _body = '可以先去做别的，过一会儿回来看结果。';

  @override
  Widget build(BuildContext context) {
    // 浅底加深，与两页说明条同一算法，不另取色。
    final deep = Color.lerp(accent, const Color(0xFF000000), 0.18)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColor.fieldFill(context)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧功能色条，和上方浅说明、下方思考正文都不同。
              ColoredBox(color: accent, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule_outlined, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: deep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _body,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: deep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
