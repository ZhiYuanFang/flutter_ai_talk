import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';

/// Apple IAP 加速验单（功能单 / 小智 MCP 共用）。
///
/// 历史 URL 仍为 `/cash/app/api/vip/apple/verify`（Go 兼容 Flutter）；
/// **不是** VIP 履约——服务端仅开通功能 Pro / 小智。权威路径为 ASN。
class CashAppleIapRepository {
  CashAppleIapRepository(this._api);

  final ApiClient _api;

  /// StoreKit 购买/恢复后可选加速验单。
  Future<void> verifyApple({
    required String transactionId,
    required String productId,
    String signedTransaction = '',
    String orderNo = '',
  }) async {
    final body = <String, dynamic>{
      'transactionId': transactionId,
      'productId': productId,
    };
    if (signedTransaction.trim().isNotEmpty) {
      body['signedTransaction'] = signedTransaction.trim();
    }
    if (orderNo.trim().isNotEmpty) {
      body['orderNo'] = orderNo.trim();
    }
    try {
      // 历史路径：履约功能/小智，非 VIP。
      await _api.postJsonEnvelope('/cash/app/api/vip/apple/verify', body);
      AppDebugLog.featureUnlock(
        'apple verify ok txLen=${transactionId.length} productId=$productId',
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.featureUnlock(
        'apple verify business err=${e.code} ${e.message}',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.featureUnlock('apple verify http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.featureUnlock('apple verify err=$e');
      rethrow;
    }
  }
}
