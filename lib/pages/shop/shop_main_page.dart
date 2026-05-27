import 'package:flutter/material.dart';
import '../../services/cart_service.dart';
import '../../widgets/shop/shop_bottom_nav_bar.dart';
import 'shop_home_page.dart';
import 'product_list_page.dart';
import 'wishlist_page.dart';
import 'cart_page.dart';

/// 商城主容器页面
/// 包含底部导航和 4 个 Tab 页面
class ShopMainPage extends StatefulWidget {
  /// 初始显示的 Tab 索引
  final int initialIndex;

  const ShopMainPage({super.key, this.initialIndex = 0});

  @override
  State<ShopMainPage> createState() => ShopMainPageState();
}

class ShopMainPageState extends State<ShopMainPage> {
  int _currentIndex = 0;
  int _cartItemCount = 0;

  // 购物车页面的 GlobalKey，用于刷新
  final GlobalKey<CartPageState> _cartPageKey = GlobalKey<CartPageState>();
  final GlobalKey<WishlistPageState> _wishlistPageKey =
      GlobalKey<WishlistPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const ShopHomePage(),
      const ProductListPage(),
      WishlistPage(key: _wishlistPageKey),
      CartPage(key: _cartPageKey),
    ];
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getItemCount();
    if (mounted) {
      setState(() => _cartItemCount = count);
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    // 切换到购物车 Tab 时刷新数据
    if (index == 3) {
      _cartPageKey.currentState?.refresh();
      _loadCartCount();
    }
    if (index == 2) {
      _wishlistPageKey.currentState?.refresh();
    }
  }

  /// 切换到指定 Tab
  void switchToTab(int index) {
    _onTabTapped(index);
  }

  void openProductListTab({String? searchQuery}) {
    final trimmed = searchQuery?.trim();
    setState(() {
      if (trimmed == null || trimmed.isEmpty) {
        _pages[1] = const ProductListPage();
      } else {
        _pages[1] = ProductListPage(
          key: ValueKey('product_list_$trimmed'),
          searchQuery: trimmed,
        );
      }
      _currentIndex = 1;
    });
  }

  /// 刷新购物车数量
  void refreshCartCount() {
    _loadCartCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '赋能商城',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ShopBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        cartItemCount: _cartItemCount,
      ),
    );
  }

  void _openSearch() {
    // TODO: 打开搜索页面
    showSearch(
      context: context,
      delegate: _ProductSearchDelegate(),
    );
  }

  /// 供子页面调用，更新购物车数量
  void updateCartCount(int count) {
    setState(() => _cartItemCount = count);
  }
}

/// 商品搜索代理
class _ProductSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => '搜索商品';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black38,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: 实现搜索结果
    return ProductListPage(searchQuery: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              '搜索商品名称',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return ProductListPage(searchQuery: query);
  }
}
