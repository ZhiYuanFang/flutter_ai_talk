import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 由根组件 `listen` 后 `SnackBar` 展示（避免在 Repository 内持有 [BuildContext]）。
final apiToastProvider = StateProvider<String?>((ref) => null);
