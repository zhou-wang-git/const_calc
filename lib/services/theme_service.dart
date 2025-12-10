import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,  // 浅色模式
  dark,   // 深色模式
  system, // 跟随系统
}

/// 主题管理服务（单例）
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';

  AppThemeMode _themeMode = AppThemeMode.light;

  /// 当前主题模式
  AppThemeMode get themeMode => _themeMode;

  /// 是否为深色模式（考虑跟随系统的情况）
  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      // 获取系统当前主题
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  /// 获取 Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// 初始化，从本地存储读取主题设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.light,
      );
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    // 持久化存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// 获取主题模式的显示名称
  static String getModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '浅色模式';
      case AppThemeMode.dark:
        return '深色模式';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取主题模式的图标
  static IconData getModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.phone_android;
    }
  }
}
