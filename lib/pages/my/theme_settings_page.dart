import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/theme_service.dart';

/// 主题设置页面
class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late AppThemeMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = ThemeService().themeMode;
  }

  Future<void> _onModeSelected(AppThemeMode mode) async {
    setState(() {
      _selectedMode = mode;
    });
    await ThemeService().setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return _buildThemeItem(
                  mode: mode,
                  isSelected: isSelected,
                  isDark: isDark,
                  theme: theme,
                  isLast: mode == AppThemeMode.values.last,
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '选择「跟随系统」后，App 将自动根据系统设置切换浅色或深色模式。',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItem({
    required AppThemeMode mode,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
    required bool isLast,
  }) {
    return InkWell(
      onTap: () => _onModeSelected(mode),
      borderRadius: isLast
          ? BorderRadius.only(
              bottomLeft: Radius.circular(12.r),
              bottomRight: Radius.circular(12.r),
            )
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(
              ThemeService.getModeIcon(mode),
              size: 24.w,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                ThemeService.getModeName(mode),
                style: TextStyle(
                  fontSize: 15.sp,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20.w,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
