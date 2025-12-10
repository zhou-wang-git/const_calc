import 'package:const_calc/pages/fortune/luck_page.dart';
import 'package:const_calc/pages/home/birthday_selection_guide_page.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_initializer.dart';
import 'dto/user.dart';
import 'pages/home/home_page.dart';
import 'pages/information/library_page.dart';
import 'pages/my/profile_page.dart';
import 'pages/login/login_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/ios_install_guide_dialog.dart';
import 'services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:universal_html/html.dart' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 监听主题变化
    ThemeService().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ScreenUtilInit(
      // 设计稿 750×1500 是 @2x，所以 /2 => 375×750
      designSize: const Size(375, 750),
      minTextAdapt: true,      // 字体自适配
      splitScreenMode: true,   // 支持分屏/平板
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const MainTabPage(),

          // 本地化
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh', 'CN'),

          // 主题模式
          themeMode: ThemeService().flutterThemeMode,

          // 浅色主题
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFC107),
              primary: const Color(0xFFFFC107),
              surface: Colors.white,
              error: const Color(0xFFD32F2F),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF3F3F3),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: 14.sp, color: Colors.black87),
              bodyLarge: TextStyle(fontSize: 16.sp, color: Colors.black87),
              titleLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),

          // 深色主题
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFC107),
              primary: const Color(0xFFFFC107),
              surface: const Color(0xFF1E1E1E),
              error: const Color(0xFFCF6679),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 0.5,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: 14.sp, color: Colors.white70),
              bodyLarge: TextStyle(fontSize: 16.sp, color: Colors.white70),
              titleLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      },
    ));
  }
}

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    LuckPage(),
    LibraryPage(),
    ProfilePage(),
  ];


  @override
  void initState() {
    super.initState();
    _bootstrap();
    _checkShowGuide();
  }

  Future<void> _bootstrap() async {
    // ✅ 不清除缓存，使用现有缓存（登录时已获取）
    // 如果缓存为空，getUserInfo() 会自动调用 API
    final User? user = await UserService().getUserInfo();
    if (user == null && !mounted) {
      return;
    }

    if (AuthService().isLoggedIn && (user?.year == null || user!.year.isEmpty || user.year == '0')) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BirthdaySelectionGuidePage()),
      );
      return;
    }
  }

  /// 检查是否需要显示iOS安装引导
  void _checkShowGuide() {
    if (!kIsWeb) return;

    // 延迟显示，避免与其他对话框冲突
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // 获取URL参数
      final uri = Uri.parse(html.window.location.href);
      final showGuide = uri.queryParameters['showGuide'];

      // 检测是否在iOS Safari浏览器
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isIOS = userAgent.contains('iphone') ||
                    userAgent.contains('ipad') ||
                    userAgent.contains('ipod');
      final isSafari = userAgent.contains('safari') &&
                       !userAgent.contains('chrome') &&
                       !userAgent.contains('crios');

      // 检测是否已在PWA模式（独立模式）
      final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;

      // 只在iOS Safari浏览器且有showGuide参数且未在PWA模式时显示引导
      if (showGuide == 'true' && isIOS && isSafari && !isStandalone) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const IosInstallGuideDialog(),
        );
      }
    });
  }

  // 需要登录的 tab 页面索引
  final Set<int> _needLoginTabs = {1, 2, 3};

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_needLoginTabs.contains(index) && !AuthService().isLoggedIn) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('提示'),
            content: const Text('请先完善个人信息'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                  if (result == true && mounted) {
                    setState(() {}); // 登录成功刷新
                  }
                },
                child: const Text('前往登录'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      // ✅ 示例：如果某些地方你想锁文字缩放（和你之前做法一样）
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: MyBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
