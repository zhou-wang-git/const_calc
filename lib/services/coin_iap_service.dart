import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../dto/coin_config.dart';
import 'coin_service.dart';

/// KCC Coin IAP 充值服务
class CoinIAPService {
  static final CoinIAPService _instance = CoinIAPService._internal();
  factory CoinIAPService() => _instance;
  CoinIAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _initialized = false;

  // 当前购买的套餐信息（用于验证回调）
  RechargePackage? _currentPackage;
  Completer<bool>? _purchaseCompleter;
  BuildContext? _currentContext;

  /// 初始化 IAP
  Future<void> initialize() async {
    if (_initialized) return;

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return;
    }

    // 监听购买更新
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP stream error: $error'),
    );

    _initialized = true;
    debugPrint('IAP initialized');
  }

  /// 购买积分套餐
  Future<bool> purchaseCoins({
    required BuildContext context,
    required RechargePackage package,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_isAvailable) {
      _showError(context, 'IAP 服务不可用');
      return false;
    }

    // 获取商品ID
    final productId = _getProductId(package);
    if (productId == null || productId.isEmpty) {
      _showError(context, '商品配置错误');
      return false;
    }

    // 查询商品信息
    final response = await _inAppPurchase.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      _showError(context, '商品未找到: $productId');
      return false;
    }

    if (response.productDetails.isEmpty) {
      _showError(context, '无法获取商品信息');
      return false;
    }

    final product = response.productDetails.first;

    // 保存当前购买信息
    _currentPackage = package;
    _currentContext = context;
    _purchaseCompleter = Completer<bool>();

    // 发起购买
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _purchaseCompleter?.complete(false);
        return false;
      }

      // 等待购买完成
      return await _purchaseCompleter!.future;
    } catch (e) {
      debugPrint('Purchase error: $e');
      _showError(context, '购买失败: $e');
      _purchaseCompleter?.complete(false);
      return false;
    }
  }

  /// 获取平台对应的商品ID
  String? _getProductId(RechargePackage package) {
    if (Platform.isIOS) {
      return package.iosProductId;
    } else if (Platform.isAndroid) {
      return package.androidProductId;
    }
    return null;
  }

  /// 处理购买更新
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      debugPrint(
          'Purchase update: ${purchase.productID}, status: ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // 购买处理中
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 购买成功，验证收据
          final success = await _verifyPurchase(purchase);

          // 完成交易（必须调用，否则会重复提醒）
          await _inAppPurchase.completePurchase(purchase);

          _purchaseCompleter?.complete(success);
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          await _inAppPurchase.completePurchase(purchase);

          if (_currentContext != null && _currentContext!.mounted) {
            _showError(_currentContext!, purchase.error?.message ?? '购买失败');
          }
          _purchaseCompleter?.complete(false);
          break;

        case PurchaseStatus.canceled:
          await _inAppPurchase.completePurchase(purchase);
          _purchaseCompleter?.complete(false);
          break;
      }
    }
  }

  /// 验证购买收据
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (_currentPackage == null) {
      debugPrint('No current package for verification');
      return false;
    }

    try {
      String receipt;
      String platform;

      if (Platform.isIOS) {
        platform = 'ios';
        // iOS 获取 receipt
        final skPurchase = purchase as AppStorePurchaseDetails;
        receipt = skPurchase.verificationData.serverVerificationData;
      } else if (Platform.isAndroid) {
        platform = 'android';
        // Android 获取 purchaseToken
        final gpPurchase = purchase as GooglePlayPurchaseDetails;
        receipt = gpPurchase.verificationData.serverVerificationData;
      } else {
        return false;
      }

      // 调用后端验证
      final result = await CoinService.verifyIAPReceipt(
        platform: platform,
        receipt: receipt,
        productId: purchase.productID,
        packageId: _currentPackage!.id,
      );

      if (result.success) {
        if (_currentContext != null && _currentContext!.mounted) {
          _showSuccess(_currentContext!, '充值成功！获得 ${result.coinsAdded} 能量点');
        }
        return true;
      } else {
        if (_currentContext != null && _currentContext!.mounted) {
          _showError(_currentContext!, result.message ?? '验证失败');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Verify error: $e');
      if (_currentContext != null && _currentContext!.mounted) {
        _showError(_currentContext!, '验证失败: $e');
      }
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
    _initialized = false;
  }
}
