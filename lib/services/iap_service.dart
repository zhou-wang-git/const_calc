import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'payment_service.dart';
import 'auth_service.dart';
import 'http_service.dart';

/// iOS Apple In-App Purchase 服务
class IAPService implements PaymentService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 产品 ID 映射（标准化版本）
  ///
  /// ✅ 符合 Apple 命名规范：com.{company}.{app}.{product}
  /// ✅ 产品类型：非续订订阅（Non-renewing subscriptions）
  ///
  /// 映射规则：{vipName}_{vipTime} -> App Store 产品 ID
  /// - vipName: elite (精英) / supreme (至尊)
  /// - vipTime: 后端传递的时长（月数）
  static const Map<String, String> _productIdMap = {
    // 精英会员
    'elite_1': 'com.kccdigital.shuyi.fn.elite.1month',   // 精英会员 1 个月
    'elite_3': 'com.kccdigital.shuyi.fn.elite.3months',  // 精英会员 3 个月
    'elite_6': 'com.kccdigital.shuyi.fn.elite.6months',  // 精英会员 6 个月
    'elite_12': 'com.kccdigital.shuyi.fn.elite.1year',   // 精英会员 12 个月

    // 至尊会员
    'supreme_1': 'com.kccdigital.shuyi.fn.supreme.1month',   // 至尊会员 1 个月
    'supreme_3': 'com.kccdigital.shuyi.fn.supreme.3months',  // 至尊会员 3 个月
    'supreme_6': 'com.kccdigital.shuyi.fn.supreme.6months',  // 至尊会员 6 个月
    'supreme_12': 'com.kccdigital.shuyi.fn.supreme.1year',   // 至尊会员 12 个月
    'supreme_-1': 'com.kccdigital.shuyi.fn.supreme.lifetime', // 至尊终身会员
  };

  /// 获取 IAP 产品 ID
  static String? getProductId(String vipName, String vipTime) {
    final key = '${vipName}_$vipTime';
    return _productIdMap[key];
  }

  @override
  Future<bool> pay({
    required BuildContext context,
    required String vipLevelId,
    required String vipName,
    required String vipTime,
    required String vipDate,
    required String amount,
    required String originalAmount,
    String currency = 'usd',
  }) async {
    try {
      // 1. 获取产品 ID
      final productId = getProductId(vipName, vipTime);
      if (productId == null) {
        _showError(context, '产品配置错误：未找到对应的 IAP 产品 ID');
        return false;
      }

      // 2. 检查 IAP 是否可用
      final available = await _iap.isAvailable();
      if (!available) {
        _showError(context, '应用内购买不可用，请检查网络或稍后再试');
        return false;
      }

      // 3. 显示加载提示
      if (!context.mounted) return false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 4. 查询产品信息
      final response = await _iap.queryProductDetails({productId});
      if (!context.mounted) return false;
      Navigator.pop(context); // 关闭加载

      if (response.notFoundIDs.isNotEmpty) {
        _showError(context, '产品未找到，请联系客服\n产品ID: $productId');
        return false;
      }

      if (response.productDetails.isEmpty) {
        _showError(context, '无法获取产品信息，请稍后再试');
        return false;
      }

      final productDetails = response.productDetails.first;

      // 5. 监听购买状态
      final completer = Completer<bool>();
      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        (purchases) => _handlePurchaseUpdate(
          purchases,
          completer,
          context,
          vipLevelId: vipLevelId,
          vipName: vipName,
          vipTime: vipTime,
          vipDate: vipDate,
          amount: amount,
          originalAmount: originalAmount,
        ),
        onError: (error) {
          completer.complete(false);
          _showError(context, '购买失败：$error');
        },
      );

      // 6. 发起购买
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _iap.buyConsumable(purchaseParam: purchaseParam);

      // 7. 等待购买结果
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _showError(context, '购买超时，请重试');
          return false;
        },
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, '购买失败：$e');
      }
      return false;
    }
  }

  /// 处理购买状态更新
  Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchases,
    Completer<bool> completer,
    BuildContext context, {
    required String vipLevelId,
    required String vipName,
    required String vipTime,
    required String vipDate,
    required String amount,
    required String originalAmount,
  }) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // 等待支付
        continue;
      } else if (purchase.status == PurchaseStatus.error) {
        // 支付失败
        if (!completer.isCompleted) {
          completer.complete(false);
          if (context.mounted) {
            _showError(context, '支付失败：${purchase.error?.message ?? "未知错误"}');
          }
        }
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // 支付成功，发送到后端验证
        final success = await _verifyPurchase(
          purchase,
          vipLevelId: vipLevelId,
          vipName: vipName,
          vipTime: vipTime,
          vipDate: vipDate,
          amount: amount,
          originalAmount: originalAmount,
        );

        if (!completer.isCompleted) {
          completer.complete(success);
          if (context.mounted) {
            if (success) {
              _showSuccess(context, '购买成功！');
            } else {
              _showError(context, '购买验证失败，请联系客服');
            }
          }
        }

        // 完成购买（清除 App Store 队列）
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        // 用户取消
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// 发送收据到后端验证
  Future<bool> _verifyPurchase(
    PurchaseDetails purchase, {
    required String vipLevelId,
    required String vipName,
    required String vipTime,
    required String vipDate,
    required String amount,
    required String originalAmount,
  }) async {
    try {
      final user = AuthService().loginUser;
      if (user == null) return false;

      // 获取 iOS 收据数据
      String? receiptData;
      if (Platform.isIOS) {
        final iosPurchase = purchase as AppStorePurchaseDetails;
        receiptData = iosPurchase.verificationData.localVerificationData;
      }

      if (receiptData == null || receiptData.isEmpty) {
        return false;
      }

      // ⚠️ 后端接口需要实现：POST /order/addIAPOrder
      // 参数：
      // - receipt: Base64 编码的 Apple 收据
      // - transaction_id: 交易 ID
      // - product_id: 产品 ID
      // - vip_level_id, vip_time, vip_name, vip_date, amount, original_amount
      // - userid, token
      //
      // 后端需要调用 Apple verifyReceipt API 验证收据真实性
      // 验证通过后给用户开通 VIP
      final res = await http.post(
        Uri.parse('${HttpService.baseUrl}/order/addIAPOrder'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'receipt': receiptData,
          'transaction_id': purchase.purchaseID ?? '',
          'product_id': purchase.productID,
          'vip_level_id': vipLevelId,
          'vip_time': vipTime,
          'vip_name': vipName,
          'vip_date': vipDate,
          'original_amount': originalAmount,
          'amount': amount,
          'userid': user.userid.toString(),
          'token': user.token ?? '',
        },
      );

      if (res.statusCode >= 400) {
        return false;
      }

      final json = jsonDecode(res.body);
      return json['code'] == 1;
    } catch (e) {
      return false;
    }
  }

  /// 恢复购买（iOS 专用功能）
  @override
  Future<void> restorePurchases(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _iap.restorePurchases();

      if (!context.mounted) return;
      Navigator.pop(context);
      _showSuccess(context, '恢复购买成功');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showError(context, '恢复购买失败：$e');
    }
  }

  /// 显示错误提示
  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示成功提示
  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
  }
}
