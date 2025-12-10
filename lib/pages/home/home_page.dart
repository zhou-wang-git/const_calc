import 'package:const_calc/dto/abs.dart';
import 'package:const_calc/handler/api_exception.dart';
import 'package:const_calc/services/abs_service.dart';
import 'package:const_calc/services/digit_calculation_service.dart';
import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/services/my_service.dart';
import 'package:const_calc/services/theme_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ SVG 支持
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ 新增
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // ✅ Cookie管理
import '../../util/web_window_stub.dart'
    if (dart.library.html) 'package:web/web.dart' as html;

import '../../component/abs_carousel.dart';
import '../../component/safe_web_view.dart';
import '../../dto/Tutor.dart';
import '../../dto/magic_link.dart';
import '../../dto/today_perpetual.dart';
import '../../dto/user.dart';
import '../../services/today_perpetual_service.dart';
import '../../services/tutor_service.dart';
import '../../services/user_service.dart';
import '../../util/auth_manager.dart';
import '../../util/http_util.dart';
import '../auspicious_time/auspicious_time_page.dart';
import '../fortune/luck_page.dart';
import 'digit_calculation_page.dart';
import 'name_calculation_page.dart';
import 'record_list_page.dart';
import 'tutor_consult_page.dart';
import 'tutor_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _avatar = 'assets/icons/avatar.png'; // 默认头像
  String _greeting = 'Hello, '; // 默认欢迎语
  List<Tutor> _tutors = []; // 导师推荐
  TodayPerpetual? _today; // 今天黄历
  List<Abs> _absList = []; // 广告
  bool _isNavigating = false; // 防止重复导航
  bool _hasCheckedLogin = false; // 标记是否已检查过登录状态

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndInit();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时重新检查登录状态
      _checkLoginAndInit();
    }
  }

  /// 检查登录状态并初始化数据
  Future<void> _checkLoginAndInit() async {
    final user = await _initUserInfo();
    if (user != null) {
      // 已登录，加载数据
      _loadTutorList();
      _loadToday();
      _loadAbsList();
    }
  }

  void _loadAbsList() async {
    try {
      final data = await HttpUtil.request<List<Abs>>(
        () => AbsService.getAbsList(position: '1'),
        context,
        () => mounted,
      );
      if (!mounted) return;
      print('HomePage _loadAbsList: loaded ${data?.length ?? 0} ads');
      setState(() => _absList = data ?? []);
    } catch (e) {
      print('HomePage _loadAbsList error: $e');
    }
  }

  void _loadToday() async {
    try {
      final data = await HttpUtil.request(
        () => TodayPerpetualService.getToday(),
        context,
        () => mounted,
      );
      if (!mounted) return;
      setState(() => _today = data);
    } catch (_) {}
  }

  // ✅ 尺寸适配版徽章
  Widget _buildBadge(String text, Color color) {
    final outer = 20.w;
    final inner = 16.w;
    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 0.5.w),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 9.sp,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ✅ 导师卡片适配
  Widget _buildTutorCard(Tutor tutor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TutorDetailPage(tutor: tutor)),
        );
      },
      child: Container(
        width: 120.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                '${HttpService.domain}${tutor.avatar}',
                height: 72.w,
                width: 72.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/icons/avatar.png',
                  height: 72.w,
                  width: 72.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              tutor.chineseName,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${tutor.experienceYears}年',
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadTutorList() async {
    try {
      final list = await HttpUtil.request(
        () => TutorService.getTutorList(),
        context,
        () => mounted,
      );
      setState(() {
        _tutors = list!.toList();
      });
    } catch (_) {}
  }

  Future<User?> _initUserInfo() async {
    try {
      final User? user = await UserService().getUserInfo();
      if (user == null) {
        // 未登录，跳转到登录页
        if (!mounted) return null;
        AuthManager.logout(context);
        return null;
      }
      // 已登录，更新UI
      if (mounted) {
        setState(() {
          _avatar = user.avatar.isNotEmpty
              ? HttpService.domain + user.avatar
              : 'assets/icons/avatar.png';
          _greeting = 'Hello, ${user.realName}';
        });
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部欢迎区
            Row(
              children: [
                CircleAvatar(
                  radius: 24.w,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: _avatar.startsWith('http')
                      ? NetworkImage(_avatar)
                      : AssetImage(_avatar) as ImageProvider,
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "欢迎使用数易赋能~",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 星盘图区域
            if (isDark)
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn, // 线条统一着色为白色
                ),
                child: Image.asset(
                  'assets/icons/star_chart.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180.h,
                ),
              )
            else
              Image.asset(
                'assets/icons/star_chart.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180.h,
              ),

            SizedBox(height: 8.h),

            // 广告
            if (_absList.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: AbsCarousel(
                    items: _absList,
                    aspectRatio: 4.2,
                    autoPlay: true,
                    clipInside: true,
                    domainPrefix: HttpService.domain,
                    onTap: (abs) async {
                      if (abs.url == null || abs.url!.isEmpty) return;
                      final Uri uri = Uri.parse(abs.url ?? '');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        MessageUtil.info(context, '无法打开链接: ${abs.url}');
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // 快捷功能区
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              margin: EdgeInsets.only(top: 1.h),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final User? user = await UserService()
                                .getUserInfo();
                            if (user == null) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              MessageUtil.info(context, '请先登录');
                              // ignore: use_build_context_synchronously
                              AuthManager.logout(context);
                              return;
                            }
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DigitCalculationPage(),
                              ),
                            );
                          },
                          child: _buildItem(
                            "数字测算",
                            "assets/icons/icon_mainicon8/nine.svg",
                            "你的生命数字",
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (_isNavigating) return; // 防止重复点击
                            setState(() => _isNavigating = true);

                            try {
                              final navigator = Navigator.of(context);
                              final User? user = await UserService()
                                  .getUserInfo();
                              if (user == null) {
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                MessageUtil.info(context, '请先登录');
                                // ignore: use_build_context_synchronously
                                AuthManager.logout(context);
                                return;
                              }
                              try {
                                await DigitCalculationService.checkAndConsumeApi(
                                  purviewId: 8,  // 姓名学 ID
                                );
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NameCalculationPage(),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                if (e is ApiException) {
                                  // ignore: use_build_context_synchronously
                                  MessageUtil.info(context, e.message);
                                } else {
                                  // ignore: use_build_context_synchronously
                                  MessageUtil.info(context, '未知错误');
                                }
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isNavigating = false);
                              }
                            }
                          },
                          child: _buildItem(
                            "姓名批算",
                            "assets/icons/icon_mainicon8/name.svg",
                            "你的姓名磁场",
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // 显示即将上线提示
                            MessageUtil.info(context, '2026年2月起上线');

                            // 原有跳转逻辑（暂时注释）
                            // final navigator = Navigator.of(context);
                            // final User? user = await UserService().getUserInfo();
                            // if (user == null) {
                            //   if (!mounted) return;
                            //   // ignore: use_build_context_synchronously
                            //   MessageUtil.info(context, '请先登录');
                            //   // ignore: use_build_context_synchronously
                            //   AuthManager.logout(context);
                            //   return;
                            // }
                            // navigator.push(
                            //   MaterialPageRoute(
                            //     builder: (_) => const LuckPage(),
                            //   ),
                            // );
                          },
                          child: _buildItem(
                            "塔罗占卜",
                            "assets/icons/icon_mainicon8/tarot.svg",
                            "你的每日指引",
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final User? user = await UserService().getUserInfo();
                            if (user == null) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              MessageUtil.info(context, '请先登录');
                              // ignore: use_build_context_synchronously
                              AuthManager.logout(context);
                              return;
                            }
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const AuspiciousTimePage(),
                              ),
                            );
                          },
                          child: _buildItem(
                            "吉时出行",
                            "assets/icons/icon_mainicon8/lucky.svg",
                            "你的出行吉凶",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: theme.dividerColor,
                    indent: 8.w,
                    endIndent: 8.w,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // 显示即将上线提示
                            MessageUtil.info(context, '2025年1月上线');

                            // 原有跳转逻辑（暂时注释）
                            // final navigator = Navigator.of(context);
                            //
                            // // 生成 Magic Link
                            // final magicLink = await HttpUtil.request<MagicLink>(
                            //   () => MyService.generateShopMagicLink(),
                            //   context,
                            //   () => mounted,
                            // );
                            //
                            // final shopUrl = magicLink?.link ?? 'https://numforlife.com/shopping';
                            //
                            // // Web 平台：同页面跳转到商城
                            // if (kIsWeb) {
                            //   // 追加主题参数，让商城同步 App 主题
                            //   final isDark = ThemeService().isDarkMode;
                            //   final themeParam = isDark ? 'dark' : 'light';
                            //   final separator = shopUrl.contains('?') ? '&' : '?';
                            //   final urlWithTheme = '$shopUrl${separator}theme=$themeParam';
                            //
                            //   // 使用 web 包直接跳转，不打开新窗口
                            //   html.window.location.href = urlWithTheme;
                            // } else {
                            //   // 原生平台使用 WebView
                            //   // 清除 WordPress 域名的 cookies，确保新鲜登录
                            //   final cookieManager = CookieManager.instance();
                            //   await cookieManager.deleteCookies(
                            //     url: WebUri('https://numforlife.com'),
                            //   );
                            //
                            //   navigator.push(
                            //     MaterialPageRoute(
                            //       builder: (_) => SafeWebViewPage(
                            //         url: shopUrl,
                            //         title: '赋能商城',
                            //         forceTextureOnAndroid: true,
                            //         disableHorizontalScroll: true,
                            //       ),
                            //     ),
                            //   );
                            // }
                          },
                          child: _buildItem(
                            "赋能商城",
                            "assets/icons/icon_mainicon8/cart.svg",
                            "选购你的工具",
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final User? user = await UserService()
                                .getUserInfo();
                            if (user == null) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              MessageUtil.info(context, '请先登录');
                              // ignore: use_build_context_synchronously
                              AuthManager.logout(context);
                              return;
                            }
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const LuckPage(),
                              ),
                            );
                          },
                          child: _buildItem(
                            "我的运势",
                            "assets/icons/icon_mainicon8/fortune.svg",
                            "任意日期运势",
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final User? user = await UserService()
                                .getUserInfo();
                            if (user == null) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              MessageUtil.info(context, '请先登录');
                              // ignore: use_build_context_synchronously
                              AuthManager.logout(context);
                              return;
                            }
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const RecordListPage(),
                              ),
                            );
                          },
                          child: _buildItem(
                            "测算记录",
                            "assets/icons/icon_mainicon8/record.svg",
                            "查看客户档案",
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final User? user = await UserService()
                                .getUserInfo();
                            if (user == null) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              MessageUtil.info(context, '请先登录');
                              // ignore: use_build_context_synchronously
                              AuthManager.logout(context);
                              return;
                            }
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const TutorConsultPage(),
                              ),
                            );
                          },
                          child: _buildItem(
                            "导师咨询",
                            "assets/icons/icon_mainicon8/consult.svg",
                            "专业导师解答",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // 黄历区域
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12.r),
                image: const DecorationImage(
                  image: AssetImage('assets/icons/border_img.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72.w, // 固定宽度（适配背景图）
                    child: Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _today?.yri ?? '',
                            style: TextStyle(
                              fontSize: 40.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFBBD08),
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_today?.ynian ?? ''}/${_today?.yyue ?? ''}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF925C13),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '农历 ${_today?.nyue ?? ''}${_today?.nri ?? ''}   ${_today?.ganzhinian ?? ''} / ${_today?.ganzhiyue ?? ''} / ${_today?.ganzhiri ?? ''}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Divider(
                          height: 0.5.h,
                          color: theme.dividerColor,
                          thickness: 0.5.h,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBadge('宜', Colors.green),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 14.w),
                                child: Text(
                                  _today?.yi ?? '',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: theme.textTheme.bodySmall?.color,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBadge('忌', Colors.red),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 14.w),
                                child: Text(
                                  _today?.ji ?? '',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: theme.textTheme.bodySmall?.color,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // 导师推荐区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/star.png',
                      width: 16.w,
                      height: 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "导师推荐",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TutorConsultPage(),
                      ),
                    );
                  },
                  child: Text(
                    "更多 >",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(top: 4.h),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const itemCountToShow = 3;
                  final spacing = 12.w;
                  final itemWidth =
                      (totalWidth - spacing * (itemCountToShow - 1)) /
                      itemCountToShow;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tutors.map((tutor) {
                        return Container(
                          width: itemWidth,
                          margin: EdgeInsets.only(right: spacing),
                          child: _buildTutorCard(tutor),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 快捷功能项适配
  Widget _buildItem(String title, String assetPath, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSvg = assetPath.endsWith('.svg');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2C)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: isSvg
              ? Padding(
                  padding: EdgeInsets.all(8.w),
                  child: SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      theme.textTheme.bodyMedium?.color ?? Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                )
              : Image.asset(assetPath, fit: BoxFit.contain),
        ),
        SizedBox(height: 6.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
