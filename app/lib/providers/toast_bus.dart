import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/widgets/app_toast.dart';

@immutable
class AppToastPayload {
  const AppToastPayload(this.message, {this.tone = AppToastTone.info});

  final String message;
  final AppToastTone tone;
}

/// 由根组件 `listen` 后经 [showAppToast] 展示（避免在 Repository 内持有 [BuildContext]）。
final apiToastProvider = StateProvider<AppToastPayload?>((ref) => null);

/// 供 [Ref] / [WidgetRef] 调用方使用。
extension ApiToastRefX on Ref {
  void showApiToast(String message, {AppToastTone tone = AppToastTone.info}) {
    read(apiToastProvider.notifier).state = AppToastPayload(message, tone: tone);
  }

  void showApiToastError(String message) {
    showApiToast(message, tone: AppToastTone.error);
  }
}

extension ApiToastWidgetRefX on WidgetRef {
  void showApiToast(String message, {AppToastTone tone = AppToastTone.info}) {
    read(apiToastProvider.notifier).state = AppToastPayload(message, tone: tone);
  }

  void showApiToastError(String message) {
    showApiToast(message, tone: AppToastTone.error);
  }
}
