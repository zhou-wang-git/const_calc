import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/coin_config.dart';
import '../../services/coin_service.dart';
import '../../services/coin_iap_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';

/// 积分充值页面
class CoinRechargePage extends StatefulWidget {
  const CoinRechargePage({super.key});

  @override
  State<CoinRechargePage> createState() => _CoinRechargePageState();
}

class _CoinRechargePageState extends State<CoinRechargePage> {
  CoinConfig? _config;
  int _selectedPackageId = 0;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await HttpUtil.request<CoinConfig>(
        () => CoinService.getConfig(),
        context,
        () => mounted,
      );

      if (!mounted) return;

      setState(() {
        _config = config;
        if (config != null && config.rechargePackages.isNotEmpty) {
          _selectedPackageId = config.rechargePackages[0].id;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  RechargePackage? get _selectedPackage {
    if (_config == null) return null;
    try {
      return _config!.rechargePackages
          .firstWhere((p) => p.id == _selectedPackageId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing || _selectedPackage == null) return;

    if (!kIsWeb && Platform.isAndroid) {
      MessageUtil.info(context, '功能后续上线');
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      bool success = false;

      if (kIsWeb) {
        // Web 平台使用外部支付
        success = await _handleExternalPayment();
      } else if (Platform.isIOS || Platform.isAndroid) {
        // iOS/Android 使用 IAP
        success = await CoinIAPService().purchaseCoins(
          context: context,
          package: _selectedPackage!,
        );
      } else {
        // 其他平台使用外部支付
        success = await _handleExternalPayment();
      }

      if (!mounted) return;
      setState(() => _isPurchasing = false);

      if (success) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      MessageUtil.error(context, '购买失败: $e');
    }
  }

  /// 外部支付流程（Web 或其他平台）
  Future<bool> _handleExternalPayment() async {
    try {
      final orderResult = await CoinService.createRechargeOrder(
        packageId: _selectedPackage!.id,
      );

      if (!mounted) return false;

      final uri = Uri.parse(orderResult.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showPaymentConfirmDialog(orderResult.orderSn);
        return false; // 等待用户确认
      } else {
        MessageUtil.error(context, '无法打开支付页面');
        return false;
      }
    } catch (e) {
      if (mounted) {
        MessageUtil.error(context, '创建订单失败: $e');
      }
      return false;
    }
  }

  /// 显示支付确认对话框
  void _showPaymentConfirmDialog(String orderSn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('支付确认'),
        content: const Text('请在打开的页面完成支付后，点击下方按钮确认'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消支付'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _checkPaymentStatus(orderSn);
            },
            child: const Text('我已完成支付'),
          ),
        ],
      ),
    );
  }

  /// 查询支付状态
  Future<void> _checkPaymentStatus(String orderSn) async {
    setState(() => _isPurchasing = true);

    try {
      final status = await CoinService.queryOrderStatus(orderSn: orderSn);

      if (!mounted) return;
      setState(() => _isPurchasing = false);

      if (status.isPaid) {
        MessageUtil.success(context, '充值成功！获得 ${status.coinsAdded} 能量点');
        Navigator.pop(context, true);
      } else if (status.isPending) {
        MessageUtil.info(context, '支付处理中，请稍后查看余额');
      } else if (status.isExpired) {
        MessageUtil.error(context, '订单已过期，请重新下单');
      } else {
        MessageUtil.info(context, '支付未完成');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      MessageUtil.error(context, '查询支付状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('充值能量点'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 套餐列表
                        Text(
                          '选择充值套餐',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPackageGrid(theme, isDark),

                        const SizedBox(height: 24),

                        // 说明
                        _buildNotice(theme, isDark),
                      ],
                    ),
                  ),
                ),

                // 底部购买按钮
                _buildBottomBar(theme),
              ],
            ),
    );
  }

  Widget _buildPackageGrid(ThemeData theme, bool isDark) {
    final packages = _config?.rechargePackages ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        final isSelected = _selectedPackageId == package.id;

        return GestureDetector(
          onTap: () => setState(() => _selectedPackageId = package.id),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 积分数
                      Text(
                        '${package.coins}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '能量点',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 价格
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.grey[700] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          package.priceFormatted,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 套餐名称标签
                if (index == packages.length - 1)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '超值',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 选中勾选
                if (isSelected)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotice(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.yellow.withOpacity(0.1)
            : Colors.yellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                '充值说明',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoticeItem('能量点永久有效，不会过期'),
          _buildNoticeItem('能量点可用于解锁付费功能'),
          _buildNoticeItem('至尊会员享受9折消费优惠'),
          _buildNoticeItem('如有问题请联系客服'),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final package = _selectedPackage;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 价格信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '应付金额',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  package?.priceFormatted ?? '--',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // 购买按钮
          SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '立即充值',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
