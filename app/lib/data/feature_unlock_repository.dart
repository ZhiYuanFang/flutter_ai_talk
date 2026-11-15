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

  /// 合成目录（含开通态 + products[] + 页级群二维码 URL）。
  Future<FeatureCatalogPayload> fetchCatalog() async {
    try {
      final data = await _api.getEnvelope('/cash/app/api/feature/catalog');
      if (data == null) {
        AppDebugLog.featureUnlock('catalog empty data');
        return const FeatureCatalogPayload();
      }
      final payload = FeatureCatalogPayload.fromJson(
        Map<String, dynamic>.from(data),
      );
      AppDebugLog.featureUnlock(
        'catalog ok count=${payload.items.length} '
        'qr=${payload.inviteGroupQrUrl.isNotEmpty}',
      );
      return payload;
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

  /// 预测 Pro 喂养资格（cash；字段同构 UCG；计入 usage）。
  Future<UcgEligibility> fetchPredictProEligibility() async {
    try {
      final data =
          await _api.getEnvelope('/cash/app/api/predict-pro/eligibility');
      if (data == null) {
        AppDebugLog.featureUnlock('predict-pro eligibility empty data');
        throw ApiBusinessException(-1, '预测 Pro 资格查询失败');
      }
      final e = UcgEligibility.fromJson(data);
      AppDebugLog.featureUnlock(
        'predict-pro eligibility ok qualified=${e.qualified} '
        'effective=${e.effectiveDays}/${e.requiredDays} remaining=${e.remainingDays}',
      );
      return e;
    } on ApiBusinessException catch (e) {
      AppDebugLog.featureUnlock(
        'predict-pro eligibility business err=${e.code} ${e.message}',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.featureUnlock(
        'predict-pro eligibility http err=${e.statusCode}',
      );
      rethrow;
    } catch (e) {
      AppDebugLog.featureUnlock('predict-pro eligibility err=$e');
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

  /// 预测能力点试用（7 日起算）；仅 basic/pro，care/growth 勿走此路径。
  Future<void> startFeatureTrial({required String featureId}) async {
    final id = featureId.trim();
    try {
      await _api.postJsonEnvelope(
        '/cash/app/api/feature/trial/start',
        {'featureId': id},
      );
      AppDebugLog.featureUnlock('trial start ok featureId=$id');
    } on ApiBusinessException catch (e) {
      AppDebugLog.featureUnlock(
        'trial start business err=${e.code} ${e.message} featureId=$id',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.featureUnlock(
        'trial start http err=${e.statusCode} featureId=$id',
      );
      rethrow;
    } catch (e) {
      AppDebugLog.featureUnlock('trial start err=$e featureId=$id');
      rethrow;
    }
  }

  /// 广告完成开通（已下线；保留方法防旧调用编译，服务端应拒绝）。
  @Deprecated('广告开通已删除')
  Future<void> completeAd({
    required String featureId,
    String idempotencyKey = '',
  }) async {
    AppDebugLog.featureUnlock(
      'ad complete rejected featureId=${featureId.trim()} (ad unlock removed)',
    );
    throw ApiBusinessException(-1, '广告开通已下线');
  }

  /// GET `/cash/app/api/invite/mine`：当前用户邀请码与成功兑换数。
  Future<InviteMine> fetchInviteMine() async {
    final data = await _api.getEnvelope('/cash/app/api/invite/mine');
    if (data == null) {
      AppDebugLog.featureUnlock('invite mine empty data');
      throw ApiBusinessException(-1, '邀请码查询失败');
    }
    final mine = InviteMine.fromJson(data);
    AppDebugLog.featureUnlock(
      'invite mine ok codeLen=${mine.code.length} redeemed=${mine.redeemedCount}',
    );
    return mine;
  }

  /// GET `/cash/app/api/invite/invitees`：成功使用我码的用户列表。
  Future<List<InviteInvitee>> fetchInviteInvitees() async {
    final data = await _api.getEnvelope('/cash/app/api/invite/invitees');
    if (data == null) {
      AppDebugLog.featureUnlock('invite invitees empty data');
      return const [];
    }
    final raw = data['list'];
    final out = <InviteInvitee>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          out.add(InviteInvitee.fromJson(e));
        } else if (e is Map) {
          out.add(InviteInvitee.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    AppDebugLog.featureUnlock('invite invitees ok count=${out.length}');
    return out;
  }
}
