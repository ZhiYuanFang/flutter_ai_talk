import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'cash_vip_models.dart';

/// Cash VIP 网关 API（经 gateway-app `/cash/app/api/vip/*`）。
class CashVipRepository {
  CashVipRepository(this._api);

  final ApiClient _api;

  /// 商品现价/原价；允许匿名（仍可带 Bearer）。
  Future<CashVipProduct?> fetchProduct() async {
    try {
      final data = await _api.getEnvelope(
        '/cash/app/api/vip/product',
        withAuthorization: true,
      );
      if (data == null) {
        AppDebugLog.cashVip('product empty data');
        return null;
      }
      final p = CashVipProduct.fromJson(data);
      AppDebugLog.cashVip(
        'product ok code=${p.productCode} priceFen=${p.priceFen} '
        'origFen=${p.originalPriceFen}',
      );
      return p;
    } on ApiBusinessException catch (e) {
      AppDebugLog.cashVip('product business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.cashVip('product http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.cashVip('product err=$e');
      rethrow;
    }
  }

  /// 当前账号 VIP 状态（需登录）。
  Future<CashVipStatus?> fetchStatus() async {
    try {
      final data = await _api.getEnvelope('/cash/app/api/vip/status');
      if (data == null) {
        AppDebugLog.cashVip('status empty data');
        return null;
      }
      final s = CashVipStatus.fromJson(data);
      AppDebugLog.cashVip('status ok isVip=${s.isVip} expireAt=${s.expireAt}');
      return s;
    } on ApiBusinessException catch (e) {
      AppDebugLog.cashVip('status business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.cashVip('status http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.cashVip('status err=$e');
      rethrow;
    }
  }

  /// 建单；[channel] 为 `alipay` 或 `apple_iap`。
  Future<CashVipOrder> createOrder({
    required String productCode,
    required String channel,
  }) async {
    final code = productCode.trim().isEmpty
        ? kCashVipDefaultProductCode
        : productCode.trim();
    final ch = channel.trim();
    final data = await _api.postJsonEnvelope(
      '/cash/app/api/vip/orders',
      {
        'productCode': code,
        'channel': ch,
      },
    );
    if (data == null) {
      AppDebugLog.cashVip('orders empty data channel=$ch');
      throw ApiBusinessException(-1, '建单失败，请稍后重试');
    }
    final order = CashVipOrder.fromJson(data);
    AppDebugLog.cashVip(
      'orders ok channel=${order.channel} orderNoLen=${order.orderNo.length} '
      'amountFen=${order.amountFen}',
    );
    return order;
  }

  /// iOS StoreKit 后验单。
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
    await _api.postJsonEnvelope('/cash/app/api/vip/apple/verify', body);
    AppDebugLog.cashVip(
      'apple verify ok txLen=${transactionId.length} productId=$productId',
    );
  }
}
