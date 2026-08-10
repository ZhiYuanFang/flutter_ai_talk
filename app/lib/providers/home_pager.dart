import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/home` PageView 页索引：喂养 | 智能预测（主页）| UCG。
abstract final class HomePagerPage {
  /// 喂养记账页（左侧）。
  static const feeding = 0;

  /// 智能预测主页（居中、默认着陆）。
  static const prediction = 1;

  /// @Deprecated('使用 HomePagerPage.prediction') 兼容旧引用。
  static const companion = prediction;
  static const ucg = 2;
  static const count = 3;
}

/// 请求主页 PageView 切到指定页（壳层 listen 后 animateTo）。
///
/// 业务说明：预测贴士、`/pangbao` 深链等非壳内控件通过此 provider 请求切页；
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

/// 旧陪伴按住说话禁滑位保留；预测页当前不使用。
final homePagerScrollBlockedProvider = StateProvider<bool>((ref) => false);
