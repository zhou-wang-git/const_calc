import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../handler/api_exception.dart';
import '../../services/shop_session_service.dart';
import '../../util/dialog_util.dart';
import '../../util/message_util.dart';
import 'shop_main_page.dart';

/// 商城欢迎页
/// 每次进入商城时展示
class ShopWelcomePage extends StatefulWidget {
  const ShopWelcomePage({super.key});

  @override
  State<ShopWelcomePage> createState() => _ShopWelcomePageState();
}

class _ShopWelcomePageState extends State<ShopWelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isEntering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enterShop() async {
    if (_isEntering) {
      return;
    }

    setState(() => _isEntering = true);

    try {
      await ShopSessionService().ensureMallSession();
      if (!mounted) {
        return;
      }

      _openShopMain();
    } on MallWalletProvisionRequiredException {
      if (!mounted) {
        return;
      }

      final shouldCreate = await DialogUtil.confirm(
        context,
        title: '创建钱包',
        content: '检测到当前账号还没有钱包，创建后才能进入商城，是否现在创建？',
        cancelText: '暂不创建',
        confirmText: '立即创建',
      );
      if (!mounted || !shouldCreate) {
        return;
      }

      await ShopSessionService().ensureMallSession(createWalletIfMissing: true);
      if (!mounted) {
        return;
      }

      MessageUtil.success(context, '钱包已创建。');
      _openShopMain();
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e is ApiException ? e.message : '进入商城失败: $e';
      MessageUtil.info(context, message);
    } finally {
      if (mounted) {
        setState(() => _isEntering = false);
      }
    }
  }

  void _openShopMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ShopMainPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: isDark
                    ? theme.scaffoldBackgroundColor
                    : const Color(0xFFF5F5F5),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                'assets/images/woman-4495395_1280.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : const Color(0xFFF5F5F5))
                          .withValues(alpha: 0.9),
                      (isDark ? Colors.black : const Color(0xFFF5F5F5))
                          .withValues(alpha: 0.7),
                      (isDark ? Colors.black : const Color(0xFFF5F5F5))
                          .withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildLogo(theme, isDark),
                    SizedBox(height: 32.h),
                    Text(
                      '赋能商城',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '发现专属于你的能量好物',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildFeatures(theme, isDark),
                    const Spacer(flex: 1),
                    _buildEnterButton(theme, isDark),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4.w,
              top: 0,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, bool isDark) {
    final iconColor = isDark ? Colors.white70 : Colors.white;
    final logoBgColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : theme.primaryColor;

    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: logoBgColor,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shopping_bag,
        size: 60.w,
        color: iconColor,
      ),
    );
  }

  Widget _buildFeatures(ThemeData theme, bool isDark) {
    final features = [
      ('精选好物', Icons.star_outline),
      ('专属优惠', Icons.local_offer_outlined),
      ('安全支付', Icons.security_outlined),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.map((feature) {
        return Column(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                feature.$2,
                size: 24.w,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              feature.$1,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEnterButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: _isEntering ? null : _enterShop,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : theme.primaryColor,
          foregroundColor: isDark ? Colors.black87 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isEntering
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black87 : Colors.white,
                  ),
                ),
              )
            : Text(
                '开始探索',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
