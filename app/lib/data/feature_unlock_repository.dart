import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'feature_unlock_models.dart';

/// 商业功能开通 App API（经 gateway `/cash/app/api/*`）。
///
/// 不在 query/body 传 deviceNo；服务端只信网关注入头。
class FeatureUnlockRepository {
  FeatureUnlockRepository(this._api);

  final ApiClient _api;

  /// 合成目录（含开通态 + products[]）。
  Future<List<FeatureCatalogItem>> fetchCatalog() async {
    try {
      final data = await _api.getEnvelope('/cash/app/api/feature/catalog');
      if (data == null) {
        AppDebugLog.featureUnlock('catalog empty data');
        return const [];
      }
      final raw = data['list'];
      final out = <FeatureCatalogItem>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            out.add(FeatureCatalogItem.fromJson(e));
          } else if (e is Map) {
            out.add(FeatureCatalogItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      AppDebugLog.featureUnlock('catalog ok count=${out.length}');
      return out;
    } on ApiBusinessException catch (e) {
      AppDebugLog.featureUnlock('catalog business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.featureUnlock('catalog http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.featureUnlock('catalog err=$e');
      rethrow;
    }
  }

  /// UCG 入场资格。
  Future<UcgEligibility> fetchUcgEligibility() async {
    try {
      final data = await _api.getEnvelope('/cash/app/api/ucg/eligibility');
      if (data == null) {
        AppDebugLog.featureUnlock('eligibility empty data');
        throw ApiBusinessException(-1, '资格查询失败');
      }
      final e = UcgEligibility.fromJson(data);
      AppDebugLog.featureUnlock(
        'eligibility ok qualified=${e.qualified} '
        'effective=${e.effectiveDays}/${e.requiredDays}',
      );
      return e;
    } on ApiBusinessException catch (e) {
      AppDebugLog.featureUnlock(
        'eligibility business err=${e.code} ${e.message}',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.featureUnlock('eligibility http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.featureUnlock('eligibility err=$e');
      rethrow;
    }
  }

  /// 值得留意喂养资格（cash；字段同构 UCG）。
  Future<UcgEligibility> fetchCareAlertEligibility() async {
    try {
      final data =
          await _api.getEnvelope('/cash/app/api/care-alert/eligibility');
      if (data == null) {
        AppDebugLog.careAlert('care eligibility empty data');
        throw ApiBusinessException(-1, '值得留意资格查询失败');
      }
      final e = UcgEligibility.fromJson(data);
      AppDebugLog.careAlert(
        'care eligibility ok qualified=${e.qualified} '
        'effective=${e.effectiveDays}/${e.requiredDays} remaining=${e.remainingDays}',
      );
      return e;
    } on ApiBusinessException catch (e) {
      AppDebugLog.careAlert(
        'care eligibility business err=${e.code} ${e.message}',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.careAlert('care eligibility http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.careAlert('care eligibility err=$e');
      rethrow;
    }
  }

  /// 功能建单。
  Future<FeatureOrder> createOrder({
    required String productCode,
    required String channel,
  }) async {
    final code = productCode.trim();
    final ch = channel.trim();
    final data = await _api.postJsonEnvelope(
      '/cash/app/api/feature/orders',
      {
        'productCode': code,
        'channel': ch,
      },
    );
    if (data == null) {
      AppDebugLog.featureUnlock('orders empty data channel=$ch');
      throw ApiBusinessException(-1, '建单失败，请稍后重试');
    }
    final order = FeatureOrder.fromJson(data);
    AppDebugLog.featureUnlock(
      'orders ok channel=${order.channel} orderNoLen=${order.orderNo.length} '
      'amountFen=${order.amountFen}',
    );
    return order;
  }

  /// 邀请码兑换单功能。
  Future<void> redeemInviteCode({
    required String code,
    required String featureId,
  }) async {
    await _api.postJsonEnvelope(
      '/cash/app/api/feature/invite-codes/redeem',
      {
        'code': code.trim(),
        'featureId': featureId.trim(),
      },
    );
    AppDebugLog.featureUnlock(
      'invite redeem ok featureId=${featureId.trim()}',
    );
  }

  /// 广告完成开通（MVP 信客户端）。
  Future<void> completeAd({
    required String featureId,
    String idempotencyKey = '',
  }) async {
    final body = <String, dynamic>{
      'featureId': featureId.trim(),
    };
    final key = idempotencyKey.trim();
    if (key.isNotEmpty) {
      body['idempotencyKey'] = key;
    }
    await _api.postJsonEnvelope('/cash/app/api/feature/ad/complete', body);
    AppDebugLog.featureUnlock('ad complete ok featureId=${featureId.trim()}');
  }
}
