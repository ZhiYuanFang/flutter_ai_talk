import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ai_quota_codes.dart';

/// Repository / WebSocket 层无 [BuildContext] 时，经根组件 listen 后弹框。
@immutable
class AiQuotaDialogRequest {
  const AiQuotaDialogRequest(this.code);

  final int code;
}

final aiQuotaDialogProvider = StateProvider<AiQuotaDialogRequest?>((ref) => null);

extension AiQuotaDialogRefX on Ref {
  void requestAiQuotaDialog(int code) {
    if (!isAiQuotaBusinessCode(code)) return;
    read(aiQuotaDialogProvider.notifier).state = AiQuotaDialogRequest(code);
  }
}

extension AiQuotaDialogWidgetRefX on WidgetRef {
  void requestAiQuotaDialog(int code) {
    if (!isAiQuotaBusinessCode(code)) return;
    read(aiQuotaDialogProvider.notifier).state = AiQuotaDialogRequest(code);
  }
}
