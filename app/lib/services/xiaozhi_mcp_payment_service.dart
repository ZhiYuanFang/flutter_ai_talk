import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../data/cash_vip_repository.dart';
import '../data/xiaozhi_mcp_models.dart';
import '../data/xiaozhi_mcp_unlock_repository.dart';
import 'vip_alipay.dart';
import 'vip_payment_service.dart';

/// 小智 MCP 永久开通支付：建单走 MCP orders；验单/支付宝与 VIP 共用入口。
class XiaozhiMcpPaymentService {
  XiaozhiMcpPaymentService(this._unlockRepo, this._vipRepo);

  final XiaozhiMcpUnlockRepository _unlockRepo;
  final CashVipRepository _vipRepo;

  /// 购买永久 SKU；成功后由调用方刷新 unlock。
  Future<VipPaymentOutcome> purchase(XiaozhiMcpProduct product) async {
    if (kIsWeb) {
      return const VipPaymentOutcome(
        success: false,
        message: '请使用手机 App 开通',
      );
    }
    if (product.productCode.trim().isEmpty) {
      return const VipPaymentOutcome(success: false, message: '商品码无效');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _purchaseApple(fallbackAppleProductId: product.appleProductId);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _purchaseAlipay();
    }
    return const VipPaymentOutcome(
      success: false,
      message: '当前平台暂不支持支付开通',
    );
  }

  Future<VipPaymentOutcome> _purchaseAlipay() async {
    try {
      final installed = await isAlipayInstalled();
      if (!installed) {
        return const VipPaymentOutcome(
          success: false,
          message: '未检测到支付宝，请安装后重试',
        );
      }
      final order = await _unlockRepo.createOrder(channel: 'alipay');
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
      if (status == '9000' || status == '8000' || status.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return const VipPaymentOutcome(
          success: true,
          message: '支付已提交，权益刷新中',
        );
      }
      return VipPaymentOutcome(success: false, message: '支付未完成（$status）');
    } on ApiBusinessException catch (e) {
      return VipPaymentOutcome(success: false, message: e.message);
    } catch (_) {
      return const VipPaymentOutcome(success: false, message: '支付失败，请稍后重试');
    }
  }

  Future<VipPaymentOutcome> _purchaseApple({
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
      final order = await _unlockRepo.createOrder(channel: 'apple_iap');
      final appleId = order.appleProductId.trim().isNotEmpty
          ? order.appleProductId.trim()
          : fallbackAppleProductId.trim();
      if (appleId.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '缺少 Apple 商品 ID',
        );
      }
      final appAccountToken = order.appAccountToken.trim();
      if (appAccountToken.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '缺少 appAccountToken，请升级服务端后重试',
        );
      }
      final response = await iap.queryProductDetails({appleId});
      if (response.productDetails.isEmpty) {
        return const VipPaymentOutcome(
          success: false,
          message: '未找到 Apple 商品',
        );
      }
      final completer = Completer<VipPaymentOutcome>();
      sub = iap.purchaseStream.listen((purchases) async {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.pending) continue;
          if (p.status == PurchaseStatus.canceled) {
            if (!completer.isCompleted) {
              completer.complete(
                const VipPaymentOutcome(
                  success: false,
                  cancelled: true,
                  message: '已取消支付',
                ),
              );
            }
            if (p.pendingCompletePurchase) {
              await iap.completePurchase(p);
            }
            continue;
          }
          if (p.status == PurchaseStatus.error) {
            if (!completer.isCompleted) {
              completer.complete(
                VipPaymentOutcome(
                  success: false,
                  message: p.error?.message ?? '购买失败',
                ),
              );
            }
            if (p.pendingCompletePurchase) {
              await iap.completePurchase(p);
            }
            continue;
          }
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            try {
              await _vipRepo.verifyApple(
                transactionId: p.purchaseID ?? '',
                productId: p.productID,
                signedTransaction: p.verificationData.serverVerificationData,
                orderNo: order.orderNo,
              );
              if (!completer.isCompleted) {
                completer.complete(
                  const VipPaymentOutcome(success: true, message: '开通成功'),
                );
              }
            } on ApiBusinessException catch (e) {
              // 透传 cash 业务文案（如异号复用交易）；空则 fallback。
              AppDebugLog.cashVip(
                'xiaozhi apple verify biz err=${e.code} ${e.message}',
              );
              final msg = e.message.trim().isEmpty
                  ? '验单失败，请稍后重试'
                  : e.message;
              if (!completer.isCompleted) {
                completer.complete(
                  VipPaymentOutcome(success: false, message: msg),
                );
              }
            } catch (e) {
              AppDebugLog.cashVip('xiaozhi apple verify err=$e');
              if (!completer.isCompleted) {
                completer.complete(
                  const VipPaymentOutcome(
                    success: false,
                    message: '验单失败，请稍后重试',
                  ),
                );
              }
            }
            if (p.pendingCompletePurchase) {
              await iap.completePurchase(p);
            }
          }
        }
      });
      final pd = response.productDetails.first;
      final ok = await iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: pd,
          applicationUserName: appAccountToken,
        ),
      );
      if (!ok && !completer.isCompleted) {
        completer.complete(
          const VipPaymentOutcome(success: false, message: '无法发起购买'),
        );
      }
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => const VipPaymentOutcome(
          success: false,
          message: '购买超时',
        ),
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.cashVip(
        'xiaozhi apple business err=${e.code} ${e.message}',
      );
      final msg =
          e.message.trim().isEmpty ? '购买失败，请稍后重试' : e.message;
      return VipPaymentOutcome(success: false, message: msg);
    } catch (e) {
      AppDebugLog.cashVip('xiaozhi apple err=$e');
      return const VipPaymentOutcome(success: false, message: '购买失败，请稍后重试');
    } finally {
      await sub?.cancel();
    }
  }
}
