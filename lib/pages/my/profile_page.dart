import 'package:auto_size_text/auto_size_text.dart';
import 'package:const_calc/pages/my/personal_info_page.dart';
import 'package:const_calc/pages/my/select_avatar_page.dart';
import 'package:const_calc/util/auth_manager.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/coin_balance.dart';
import '../../dto/user.dart';
import '../../services/auth_service.dart';
import '../../services/coin_service.dart';
import '../../services/http_service.dart';
import '../../services/user_service.dart';
import '../../util/dialog_util.dart';
import '../../util/http_util.dart';
import 'about_page.dart';
import 'change_password_page.dart';
import 'feedback_page.dart';
import 'member_privilege_page.dart';
import 'order_list_page.dart';
import 'theme_settings_page.dart';
import 'wallet_page.dart';
import 'become_tutor_page.dart';
import '../shop/shop_order_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  String _avatar = 'assets/icons/avatar.png'; // 默认头像
  String _greeting = ''; // 默认欢迎语
  int _vipLevelId = 1;
  User? _userInfo;
  CoinBalance? _coinBalance;

  @override
  void initState() {
    super.initState();
    // 页面加载完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    // 1. 先用缓存数据快速显示（如果有）
    final cachedUser = UserService.getCachedUser();
    if (cachedUser != null) {
      _updateUIFromUser(cachedUser);
    }
    final cachedBalance = CoinService.getCachedBalance();
    if (cachedBalance != null && mounted) {
      setState(() => _coinBalance = cachedBalance);
    }

    // 2. 后台静默刷新最新数据
    await Future.wait<dynamic>([
      _refreshUserInfo(),
      _refreshCoinBalance(),
    ]);
  }

  /// 退出登录
  Future<void> _handleLogout() async {
    final confirmed = await DialogUtil.confirm(
      context,
      title: "确认退出登录？",
      content: "退出后将返回登录页面",
      cancelText: "取消",
      confirmText: "退出",
    );
    if (!mounted || !confirmed) return;

    await AuthService().logout();

    if (!mounted) return;
    MessageUtil.info(context, '已退出登录');

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    AuthManager.logout(context);
  }

  /// 从 User 对象更新 UI
  void _updateUIFromUser(User user) {
    if (!mounted) return;
    setState(() {
      _userInfo = user;
      _vipLevelId = user.vipLevelId;
      _avatar = user.avatar.isNotEmpty
          ? HttpService.domain + user.avatar
          : 'assets/icons/avatar.png';
      _greeting = user.realName;
    });
  }

  Future<CoinBalance?> _refreshCoinBalance() async {
    try {
      final balance = await CoinService.getBalance();
      if (!mounted) return balance;
      setState(() => _coinBalance = balance);
      return balance;
    } catch (e) {
      return null;
    }
  }

  /// 静默刷新用户信息（不显示 loading）
  Future<User?> _refreshUserInfo() async {
    try {
      final User? user = await UserService().refreshUserInfo();
      if (user != null) {
        _updateUIFromUser(user);
      }
      return user;
    } catch (e) {
      // 静默刷新失败，保持当前显示
      return null;
    }
  }

  /// 强制刷新用户信息（子页面返回时调用）
  Future<void> _initUserInfo() async {
    try {
      final User? user = await HttpUtil.request<User?>(
        () => UserService().refreshUserInfo(),
        context,
        () => mounted,
      );
      if (user == null) {
        return;
      }
      _updateUIFromUser(user);
    } catch (e) {
      // 已在 HttpUtil 中统一处理错误，无需重复提示
    }
  }

  Widget _buildAvatar() {
    void changeAvatar() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectAvatarPage()),
      ).then((changed) {
        if (changed == true && mounted) {
          _initUserInfo();
        }
      });
    }

    final theme = Theme.of(context);

    return Stack(
      children: [
        // 点击头像也可以
        GestureDetector(
          onTap: changeAvatar,
          child: CircleAvatar(
            radius: 56,
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: _avatar.startsWith('http')
                ? NetworkImage(_avatar)
                : AssetImage(_avatar) as ImageProvider,
          ),
        ),
        // 点击相机图标也可以
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: changeAvatar,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.13),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/icons/camera.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSummaryCard(ThemeData theme, bool isDark) {
    final cardColor = theme.cardTheme.color ?? theme.cardColor;
    final accentColor =
        isDark ? const Color(0xFFE6B957) : theme.colorScheme.primary;
    final valueColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF111827));
    final secondaryColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white70 : const Color(0xFF6B7280));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: accentColor,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AutoSizeText(
                    _coinSummaryValue,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: secondaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AutoSizeText(
                    _memberExpiryText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const MemberPrivilegePage()),
        ).then((value) {
          if (mounted && value == true) {
            _initUserInfo();
            _refreshCoinBalance();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            filterQuality: FilterQuality.high,
            image: AssetImage('assets/icons/v$_vipLevelId.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 2124 / 737,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 头像区域
            // 头像区域（带右下角相机图标）
            Stack(alignment: Alignment.center, children: [_buildAvatar()]),

            const SizedBox(height: 8),
            Text(
              _greeting,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),

            _buildAccountSummaryCard(theme, isDark),
            const SizedBox(height: 12),

            // 基础会员卡片
            _buildMemberCard(),
            if (_showLegacyMemberCard)
              GestureDetector(
                onTap: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MemberPrivilegePage()),
                  ).then((value) {
                    if (mounted && value == true) {
                      _initUserInfo();
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      filterQuality: FilterQuality.high,
                      image: AssetImage('assets/icons/v$_vipLevelId.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 2124 / 737, // 用图片的原始宽高比
                    child: Container(),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 列表项模块
            _buildListItem(
              "我的钱包",
              'assets/icons/pay.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                ).then((_) {
                  if (mounted) {
                    _initUserInfo();
                    _refreshCoinBalance();
                  }
                });
              },
            ),
            _buildListItem(
              "关于我们",
              'assets/icons/about.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                );
              },
            ),
            _buildListItem(
              "个人信息",
              'assets/icons/user.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                );
              },
            ),
            _buildListItem(
              "修改密码",
              'assets/icons/lock.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
            _buildListItem(
              "意见反馈",
              'assets/icons/callback.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackPage()),
                );
              },
            ),
            _buildListItem(
              "消费记录",
              'assets/icons/pay.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderListPage()),
                );
              },
            ),
            _buildListItem(
              "商城订单",
              'assets/icons/pay.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopOrderListPage()),
                );
              },
            ),
            _buildListItem(
              "主题设置",
              'assets/icons/setting.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
                );
              },
            ),
            _buildListItem(
              "成为导师",
              'assets/icons/tutor_apply.svg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BecomeTutorPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            // 退出按钮
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "退出",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Image.asset(
                      'assets/icons/logout.png',
                      width: 20,
                      height: 20,
                      color: isDark ? Colors.white70 : null,
                    ),
                  ],
                ),
              ),
            ),

            // 邮件提示文字
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@kccdigital.com',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                child: AutoSizeText.rich(
                  TextSpan(
                    text: "若有任何疑问/意见/技术问题，请联系 ",
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    children: [
                      TextSpan(
                        text: "support@kccdigital.com",
                        style: (theme.textTheme.bodySmall ??
                                const TextStyle(fontSize: 12))
                            .copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String iconPath, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
            ),
            child: Row(
              children: [
                _buildListIcon(iconPath, isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 0,
              thickness: 0.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListIcon(String iconPath, bool isDark) {
    if (iconPath.toLowerCase().endsWith('.svg')) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF7F7F7),
        ),
        child: SvgPicture.asset(
          iconPath,
          colorFilter:
              const ColorFilter.mode(Color(0xFF6F6F6F), BlendMode.srcIn),
        ),
      );
    }

    return Image.asset(
      iconPath,
      width: 40,
      height: 40,
    );
  }

  bool get _showLegacyMemberCard => false;

  String get _coinSummaryValue {
    if (_coinBalance == null) return '--';
    if (_coinBalance!.isFreeUser) return '∞';
    return '${_coinBalance!.coins}';
  }

  String get _memberExpiryText {
    final user = _userInfo;
    if (user == null) return '--';

    final vipEnd = _normalizeDateText(user.vipSubscriptionEnd);
    if (vipEnd.isNotEmpty) return vipEnd;

    if (user.overduedate > 0) {
      return _formatUnixDate(user.overduedate);
    }

    final vipDate = _normalizeDateText(user.vipDate);
    if (vipDate.isNotEmpty) return vipDate;

    if (user.order?.vipDate.isNotEmpty == true) {
      return user.order!.vipDate;
    }

    return user.vipLevelId == 1 ? '长期有效' : '待更新';
  }

  String _normalizeDateText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.contains('T')) {
      return trimmed.split('T').first;
    }
    if (trimmed.contains(' ')) {
      return trimmed.split(' ').first;
    }
    return trimmed;
  }

  String _formatUnixDate(int seconds) {
    try {
      final date =
          DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: false);
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } catch (_) {
      return '--';
    }
  }
}
