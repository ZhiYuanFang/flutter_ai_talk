import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../data/cash_vip_models.dart';
import '../data/cash_vip_repository.dart';
import 'vip_alipay.dart';

/// 支付结果（供 UI Toast / 导航）。
class VipPaymentOutcome {
  const VipPaymentOutcome({
    required this.success,
    this.message = '',
    this.cancelled = false,
  });

  final bool success;
  final String message;
  final bool cancelled;
}

/// VIP 支付编排：iOS Apple IAP + verify；Android 支付宝 + status 有界轮询。
class VipPaymentService {
  VipPaymentService(this._repo);

  final CashVipRepository _repo;

  /// 支付宝回前台轮询 single-flight。
  Future<bool>? _alipayPollInFlight;

  /// 按平台发起开通；[product] 来自商品接口。
  Future<VipPaymentOutcome> purchase(CashVipProduct product) async {
    if (kIsWeb) {
      return const VipPaymentOutcome(
        success: false,
        message: '请使用手机 App 开通 VIP',
      );
    }
    final code = product.productCode.trim().isEmpty
        ? kCashVipDefaultProductCode
        : product.productCode.trim();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _purchaseApple(productCode: code, fallbackAppleProductId: product.appleProductId);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _purchaseAlipay(productCode: code);
    }
    return const VipPaymentOutcome(
      success: false,
      message: '当前平台暂不支持开通 VIP',
    );
  }

  /// 支付宝 SDK 返回后或 App resumed：有界轮询 status。
  Future<bool> pollStatusUntilVip({
    int maxAttempts = 8,
    Duration interval = const Duration(milliseconds: 1500),
  }) {
    final existing = _alipayPollInFlight;
    if (existing != null) return existing;

    final fut = _doPollStatusUntilVip(
      maxAttempts: maxAttempts,
      interval: interval,
    );
    _alipayPollInFlight = fut;
    fut.whenComplete(() {
      if (identical(_alipayPollInFlight, fut)) {
        _alipayPollInFlight = null;
      }
    });
    return fut;
  }

  Future<bool> _doPollStatusUntilVip({
    required int maxAttempts,
    required Duration interval,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (i > 0) await Future<void>.delayed(interval);
      try {
        final s = await _repo.fetchStatus();
        if (s?.isVip == true) {
          AppDebugLog.cashVip('poll status vip=true attempt=${i + 1}');
          return true;
        }
      } catch (e) {
        AppDebugLog.cashVip('poll status err=$e attempt=${i + 1}');
      }
    }
    AppDebugLog.cashVip('poll status gaveUp attempts=$maxAttempts');
    return false;
  }

  Future<VipPaymentOutcome> _purchaseAlipay({required String productCode}) async {
    try {
      final installed = await isAlipayInstalled();
      if (!installed) {
        return const VipPaymentOutcome(
          success: false,
          message: '未检测到支付宝，请安装后重试',
        );
      }
      final order = await _repo.createOrder(
        productCode: productCode,
        channel: 'alipay',
      );
      final orderStr = order.alipayOrderStr.trim();
      if (orderStr.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '建单成功但缺少支付串，请稍后重试',
        );
      }
      final result = await payWithAlipay(orderStr);
      final status = '${result['resultStatus'] ?? ''}';
      if (status == '6001') {
        return const VipPaymentOutcome(
          success: false,
          cancelled: true,
          message: '已取消支付',
        );
      }
      // 9000 成功 / 8000 处理中：以服务端 notify + status 为准
      if (status == '9000' || status == '8000' || status.isEmpty) {
        final vip = await pollStatusUntilVip();
        if (vip) {
          return const VipPaymentOutcome(success: true, message: 'VIP 已开通');
        }
        return const VipPaymentOutcome(
          success: false,
          message: '若已支付请稍后返回查看 VIP 状态',
        );
      }
      return VipPaymentOutcome(
        success: false,
        message: '支付未完成（$status）',
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.cashVip('alipay business err=${e.code} ${e.message}');
      return VipPaymentOutcome(success: false, message: e.message);
    } catch (e) {
      AppDebugLog.cashVip('alipay err=$e');
      return const VipPaymentOutcome(success: false, message: '支付失败，请稍后重试');
    }
  }

  Future<VipPaymentOutcome> _purchaseApple({
    required String productCode,
    required String fallbackAppleProductId,
  }) async {
    final iap = InAppPurchase.instance;
    StreamSubscription<List<PurchaseDetails>>? sub;
    try {
      final available = await iap.isAvailable();
      if (!available) {
        return const VipPaymentOutcome(
          success: false,
          message: '应用内购买不可用',
        );
      }

      final order = await _repo.createOrder(
        productCode: productCode,
        channel: 'apple_iap',
      );
      final appleId = order.appleProductId.trim().isNotEmpty
          ? order.appleProductId.trim()
          : fallbackAppleProductId.trim();
      if (appleId.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '缺少 Apple 商品 ID，请检查服务端配置',
        );
      }

      final resp = await iap.queryProductDetails({appleId});
      if (resp.error != null) {
        AppDebugLog.cashVip('iap query err=${resp.error}');
        return const VipPaymentOutcome(
          success: false,
          message: '无法加载 App Store 商品',
        );
      }
      if (resp.productDetails.isEmpty) {
        AppDebugLog.cashVip('iap product missing id=$appleId');
        return VipPaymentOutcome(
          success: false,
          message: 'App Store 未找到商品 $appleId',
        );
      }
      final productDetails = resp.productDetails.first;

      final completer = Completer<PurchaseDetails>();
      sub = iap.purchaseStream.listen(
        (list) {
          for (final p in list) {
            if (p.productID != appleId) continue;
            if (p.status == PurchaseStatus.pending) continue;
            if (!completer.isCompleted) completer.complete(p);
          }
        },
        onError: (Object e, StackTrace st) {
          AppDebugLog.cashVip('iap stream err=$e');
          if (!completer.isCompleted) {
            completer.completeError(e, st);
          }
        },
      );

      final ok = await iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
      );
      if (!ok) {
        return const VipPaymentOutcome(
          success: false,
          message: '无法发起购买',
        );
      }

      final purchase = await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException('购买超时'),
      );

      if (purchase.status == PurchaseStatus.canceled) {
        if (purchase.pendingCompletePurchase) {
          await iap.completePurchase(purchase);
        }
        return const VipPaymentOutcome(
          success: false,
          cancelled: true,
          message: '已取消购买',
        );
      }
      if (purchase.status == PurchaseStatus.error) {
        if (purchase.pendingCompletePurchase) {
          await iap.completePurchase(purchase);
        }
        final msg = purchase.error?.message ?? '购买失败';
        AppDebugLog.cashVip('iap purchase error=$msg');
        return VipPaymentOutcome(success: false, message: msg);
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        return const VipPaymentOutcome(success: false, message: '购买未完成');
      }

      final txId = (purchase.purchaseID ?? '').trim();
      if (txId.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '缺少交易号，请联系客服',
        );
      }
      // StoreKit2：serverVerificationData 多为 JWS；沙箱无 JWS 时靠服务端 DEV_BYPASS
      final jws = purchase.verificationData.serverVerificationData;

      await _repo.verifyApple(
        transactionId: txId,
        productId: purchase.productID,
        signedTransaction: jws,
        orderNo: order.orderNo,
      );

      if (purchase.pendingCompletePurchase) {
        await iap.completePurchase(purchase);
      }

      final status = await _repo.fetchStatus();
      if (status?.isVip == true) {
        return const VipPaymentOutcome(success: true, message: 'VIP 已开通');
      }
      return const VipPaymentOutcome(
        success: true,
        message: '验单成功，权益稍后生效',
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.cashVip('apple business err=${e.code} ${e.message}');
      return VipPaymentOutcome(success: false, message: e.message);
    } on TimeoutException catch (e) {
      AppDebugLog.cashVip('apple timeout err=$e');
      return const VipPaymentOutcome(success: false, message: '购买超时，请重试');
    } catch (e) {
      AppDebugLog.cashVip('apple err=$e');
      return const VipPaymentOutcome(success: false, message: '购买失败，请稍后重试');
    } finally {
      await sub?.cancel();
    }
  }
}
