import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/home` PageView 页索引：陪伴 | 喂养 | UCG。
abstract final class HomePagerPage {
  static const companion = 0;
  static const feeding = 1;
  static const ucg = 2;
  static const count = 3;
}

/// 请求主页 PageView 切到指定页（壳层 listen 后 animateTo）。
///
/// 业务说明：tip 点卡、`/pangbao` 深链、左缘拉条等非壳内控件通过此 provider 请求切页；
/// 值为 null 表示无待处理请求；壳层消费后应 clear。
final homePagerRequestProvider =
    NotifierProvider<HomePagerRequestNotifier, int?>(HomePagerRequestNotifier.new);

class HomePagerRequestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// 请求切到 [page]（须为 [HomePagerPage] 常量之一）。
  void requestPage(int page) {
    state = page;
  }

  /// 壳层已处理请求后清空，避免重复 animate。
  void clear() {
    state = null;
  }
}

/// 陪伴页按住说话时为 true，壳层暂停 PageView 横滑，避免与上滑取消冲突。
final homePagerScrollBlockedProvider = StateProvider<bool>((ref) => false);
