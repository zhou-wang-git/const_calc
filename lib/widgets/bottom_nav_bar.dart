import 'package:flutter/material.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // 获取 icon 路径
  String _getIconPath(int index, bool selected) {
    switch (index) {
      case 0:
        return selected ? 'assets/icons/home_selected.png' : 'assets/icons/home.png';
      case 1:
        return selected ? 'assets/icons/luck_selected.png' : 'assets/icons/luck.png';
      case 2:
        return selected ? 'assets/icons/library_selected.png' : 'assets/icons/library.png';
      case 3:
        return selected ? 'assets/icons/profile_selected.png' : 'assets/icons/profile.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 深色模式用更亮的金黄色确保可见
    final selectedColor = isDark ? const Color(0xFFFFD54F) : theme.primaryColor;

    return BottomNavigationBar(
      backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: onTap,
      selectedItemColor: selectedColor,
      unselectedItemColor: isDark ? Colors.white60 : Colors.grey,
      items: List.generate(4, (index) {
        return BottomNavigationBarItem(
          icon: Image.asset(
            _getIconPath(index, false),
            width: 24,
            height: 24,
            color: isDark ? Colors.white60 : null,
          ),
          activeIcon: Image.asset(
            _getIconPath(index, true),
            width: 24,
            height: 24,
          ),
          label: ['首页', '我的运势', '资料库', '账号管理'][index],
        );
      }),
    );
  }
}
