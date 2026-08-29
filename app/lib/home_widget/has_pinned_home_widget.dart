import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../api/app_debug_log.dart';
import 'home_widget_constants.dart';

/// 桌面是否已钉至少一个胖宝小组件。
///
/// Web / 非移动 / 查询失败 → `false`（按「未添加」引导）。
Future<bool> hasPinnedHomeWidget() async {
  if (kIsWeb) return false;
  if (!(Platform.isAndroid || Platform.isIOS)) return false;
  try {
    final list = await HomeWidget.getInstalledWidgets();
    if (list.isEmpty) return false;
    // Android：仅认胖宝三 Provider；iOS：有安装记录即可
    if (Platform.isAndroid) {
      const names = {
        HomeWidgetConstants.androidSmallName,
        HomeWidgetConstants.androidMediumName,
        HomeWidgetConstants.androidLargeName,
      };
      final hit = list.any((w) {
        final cls = w.androidClassName ?? '';
        return names.any((n) => cls.contains(n));
      });
      AppDebugLog.homeWidget(
        'installed count=${list.length} pinnedPangbao=$hit',
      );
      return hit;
    }
    AppDebugLog.homeWidget('installed iOS count=${list.length}');
    return true;
  } catch (e) {
    AppDebugLog.homeWidget('getInstalledWidgets err=$e');
    return false;
  }
}
