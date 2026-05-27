import 'package:flutter/material.dart';

/// 商城底部导航栏
class ShopBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartItemCount;

  const ShopBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor = isDark ? const Color(0xFFFFD54F) : theme.primaryColor;
    final unselectedColor = isDark ? Colors.white60 : Colors.grey;
    final backgroundColor = isDark ? theme.cardTheme.color : Colors.white;

    return BottomNavigationBar(
      backgroundColor: backgroundColor,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: onTap,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, color: unselectedColor),
          activeIcon: Icon(Icons.home, color: selectedColor),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined, color: unselectedColor),
          activeIcon: Icon(Icons.grid_view, color: selectedColor),
          label: '商品',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline, color: unselectedColor),
          activeIcon: Icon(Icons.favorite, color: selectedColor),
          label: '心愿单',
        ),
        BottomNavigationBarItem(
          icon: _buildCartIcon(unselectedColor, false),
          activeIcon: _buildCartIcon(selectedColor, true),
          label: '购物车',
        ),
      ],
    );
  }

  Widget _buildCartIcon(Color color, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
          color: color,
        ),
        if (cartItemCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                cartItemCount > 99 ? '99+' : '$cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
