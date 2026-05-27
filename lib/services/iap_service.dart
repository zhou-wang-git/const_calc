import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'payment_service.dart';
import 'auth_service.dart';
import 'http_service.dart';

/// iOS/Android In-App Purchase 服务
/// 支持 Apple App Store 和 Google Play Store
class IAPService implements PaymentService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 初始化 IAP 服务（必须在应用启动时调用）
  Future<void> initialize() async {
    print('[IAP] Initializing IAP service...');

    // 检查 IAP 是否可用
    final available = await _iap.isAvailable();
    if (!available) {
      print('[IAP] IAP not available on this device');
      return;
    }

    print('[IAP] IAP service initialized and ready');
  }

  /// iOS 产品 ID 映射（Apple App Store）
  ///
  /// ✅ 符合 Apple 命名规范：{bundleId}.{product}
  /// ✅ 产品类型：非续订订阅（Non-renewing subscriptions）
  static const Map<String, String> _iosProductIdMap = {
    // 精英会员（vipTime 为天数）
    'elite_30': 'app.numforlife.com.elite.1month',
    'elite_90': 'app.numforlife.com.elite.3months',
    'elite_180': 'app.numforlife.com.elite.6months',
    'elite_365': 'app.numforlife.com.elite.1year',

    // 至尊会员（vipTime 为天数）
    'supreme_30': 'app.numforlife.com.supreme.1month',
    'supreme_90': 'app.numforlife.com.supreme.3months',
    'supreme_180': 'app.numforlife.com.supreme.6months',
    'supreme_365': 'app.numforlife.com.supreme.1year',
  };

  /// Android 产品 ID 映射（Google Play Store）
  ///
  /// ✅ 符合 Google 命名规范：只能用字母、数字和下划线
  /// ✅ 产品类型：一次性商品（One-time products）
  static const Map<String, String> _androidProductIdMap = {
    // 精英会员（vipTime 为天数）
    'elite_30': 'elite_1month',
    'elite_90': 'elite_3months',
    'elite_180': 'elite_6months',
    'elite_365': 'elite_1year',

    // 至尊会员（vipTime 为天数）
    'supreme_30': 'supreme_1month',
    'supreme_90': 'supreme_3months',
    'supreme_180': 'supreme_6months',
    'supreme_365': 'supreme_1year',
  };

  /// 获取 IAP 产品 ID（根据平台自动选择）
  static String? getProductId(String vipName, String vipTime) {
    final key = '${vipName}_$vipTime';
    if (Platform.isIOS) {
      return _iosProductIdMap[key];
    } else if (Platform.isAndroid) {
      return _androidProductIdMap[key];
    }
    return null;
  }

  /// 获取所有产品 ID 列表（用于批量查询）
  static Set<String> getAllProductIds() {
    if (Platform.isIOS) {
      return _iosProductIdMap.values.toSet();
    } else if (Platform.isAndroid) {
      return _androidProductIdMap.values.toSet();
    }
    return {};
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
      print('[IAP] Product details: id=${productDetails.id}, title=${productDetails.title}, price=${productDetails.price}');

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
              // 显示详细错误信息用于调试
              _showError(context, '购买验证失败\n\n错误详情:\n$_lastVerifyError');
            }
          }
        }

        // ✅ 只有验证成功才完成购买（消费产品）
        // 验证失败时保留购买记录，用户可以联系客服或重试
        if (success) {
          // Android 需要显式消费消耗型产品
          if (Platform.isAndroid) {
            final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
            final consumeResponse = await androidAddition.consumePurchase(purchase);

            if (consumeResponse.responseCode == BillingResponse.ok) {
              print('[IAP] Android purchase consumed successfully');
            } else {
              print('[IAP] Android consume failed: ${consumeResponse.responseCode}');
            }
          }

          await _iap.completePurchase(purchase);
          print('[IAP] Purchase completed and consumed');
        } else {
          print('[IAP] Purchase NOT completed due to verification failure');
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        // 用户取消
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// 存储最后一次验证错误信息（用于 UI 显示）
  String _lastVerifyError = '';

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
    _lastVerifyError = '';

    try {
      final user = AuthService().loginUser;
      if (user == null) {
        _lastVerifyError = '用户未登录 (user == null)';
        print('[IAP] Error: $_lastVerifyError');
        return false;
      }

      print('[IAP] User: ${user.userid}, token: ${user.token?.substring(0, 10) ?? "null"}...');
      print('[IAP] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      print('[IAP] Purchase type: ${purchase.runtimeType}');
      print('[IAP] Verification source: ${purchase.verificationData.source}');

      // 获取收据/购买令牌
      String verificationData;
      String apiEndpoint;

      if (Platform.isIOS) {
        // iOS: 使用 serverVerificationData 或 localVerificationData
        verificationData = purchase.verificationData.serverVerificationData;
        print('[IAP] iOS server verification data length: ${verificationData.length}');

        if (verificationData.isEmpty) {
          verificationData = purchase.verificationData.localVerificationData;
          print('[IAP] Fallback to local data, length: ${verificationData.length}');
        }
        apiEndpoint = '${HttpService.baseUrl}/order/addIAPOrder';
      } else if (Platform.isAndroid) {
        // Android: 使用 purchaseToken (serverVerificationData)
        verificationData = purchase.verificationData.serverVerificationData;
        print('[IAP] Android purchase token length: ${verificationData.length}');
        apiEndpoint = '${HttpService.baseUrl}/order/addGooglePlayOrder';
      } else {
        _lastVerifyError = '不支持的平台';
        print('[IAP] Error: $_lastVerifyError');
        return false;
      }

      if (verificationData.isEmpty) {
        _lastVerifyError = '收据/令牌数据为空';
        print('[IAP] Error: $_lastVerifyError');
        return false;
      }

      print('[IAP] Sending to server...');
      print('[IAP] URL: $apiEndpoint');
      print('[IAP] product_id: ${purchase.productID}');
      print('[IAP] transaction_id: ${purchase.purchaseID}');

      final requestBody = {
        'receipt': verificationData, // iOS: receipt, Android: purchaseToken
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
      };

      // Android 需要额外传递 packageName
      if (Platform.isAndroid) {
        requestBody['package_name'] = 'uni.UNI4377E5D';
      }

      final res = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      print('[IAP] Server response: ${res.statusCode}');
      print('[IAP] Response body: ${res.body}');

      if (res.statusCode >= 400) {
        _lastVerifyError = 'HTTP错误: ${res.statusCode}\n${res.body}';
        print('[IAP] Error: $_lastVerifyError');
        return false;
      }

      final json = jsonDecode(res.body);
      print('[IAP] Server code: ${json['code']}, msg: ${json['msg']}');

      if (json['code'] != 1) {
        _lastVerifyError = '服务器返回错误: ${json['msg'] ?? "未知"}';
        print('[IAP] Error: $_lastVerifyError');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _lastVerifyError = '异常: $e';
      print('[IAP] Exception: $e');
      print('[IAP] StackTrace: $stackTrace');
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
