import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 追问进入树洞前暂存的 `followUpPrompt`（原样消费一次后清空）。
final careAlertFollowUpPromptProvider =
    StateProvider<String?>((ref) => null);
