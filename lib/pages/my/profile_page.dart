import 'package:auto_size_text/auto_size_text.dart';
import 'package:const_calc/pages/my/personal_info_page.dart';
import 'package:const_calc/pages/my/select_avatar_page.dart';
import 'package:const_calc/util/auth_manager.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/abs_carousel.dart';
import '../../dto/abs.dart';
import '../../dto/user.dart';
import '../../services/abs_service.dart';
import '../../services/auth_service.dart';
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  String _avatar = 'assets/icons/avatar.png'; // 默认头像
  String _greeting = ''; // 默认欢迎语
  int _vipLevelId = 1;
  List<Abs> _absList = []; // 广告

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

    // 2. 后台静默刷新最新数据
    await _refreshUserInfo();

    // 3. 加载广告（用户信息刷新后）
    _loadAbsList();
  }

  Future<void> _loadAbsList() async {
    try {
      final data = await HttpUtil.request<List<Abs>>(
            () => AbsService.getAbsList(position: '2'),
        context,
            () => mounted,
      );
      if (!mounted) return;
      print('ProfilePage _loadAbsList: loaded ${data?.length ?? 0} ads');
      // 打印广告详情
      for (var i = 0; i < (data?.length ?? 0); i++) {
        final abs = data![i];
        print('ProfilePage ad[$i]: id=${abs.id}, imageUrl=${abs.imageUrl}, title=${abs.title}');
      }
      setState(() => _absList = data ?? []);
    } catch (e) {
      print('ProfilePage _loadAbsList error: $e');
    }
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
      _vipLevelId = user.vipLevelId;
      _avatar = user.avatar.isNotEmpty
          ? HttpService.domain + user.avatar
          : 'assets/icons/avatar.png';
      _greeting = user.realName;
    });
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
                    color: theme.shadowColor.withOpacity(0.13),
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

            // 广告
            if (_absList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, // 撑满父容器可用宽度（减去左右16间距）
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AbsCarousel(
                      items: _absList,
                      aspectRatio: 4.2, // 或者外层给固定 height
                      autoPlay: true,
                      clipInside: true,
                      domainPrefix: HttpService.domain, // 补全 /uploads/xx.jpg
                      onTap: (abs) async {
                        // 跳转/埋点
                        if (abs.url == null || abs.url!.isEmpty) return;

                        final Uri uri = Uri.parse(abs.url ?? '');
                        if (await canLaunchUrl(uri)) {
                          // 在外部浏览器打开
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // ignore: use_build_context_synchronously
                          MessageUtil.info(context, '无法打开链接: ${abs.url}');
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],

            // 基础会员卡片
            GestureDetector(
              onTap: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberPrivilegePage()),
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
              "主题设置",
              'assets/icons/setting.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
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
                    path: 'shuyi.fn@gmail.com',
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
                        text: "shuyi.fn@gmail.com",
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
                Image.asset(
                  iconPath,
                  width: 40,
                  height: 40,
                ),
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
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}
