import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../component/abs_carousel.dart';
import '../../dto/abs.dart';
import '../../dto/shop/shop_dto.dart';
import '../../services/abs_service.dart';
import '../../services/http_service.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';
import 'shop_main_page.dart';

/// 商城首页
/// 展示搜索、广告和热门商品
class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Abs> _ads = [];
  List<Product> _homeProducts = [];
  String _homeProductTitle = '热门商品';

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Abs> ads = [];
      List<Product> homeProducts = [];
      String homeProductTitle = '热门商品';
      try {
        ads = await AbsService.getAbsList(position: '3');
      } catch (_) {
        ads = [];
      }
      try {
        homeProducts = await ShopService.getPopularProducts(perPage: 4);
        if (homeProducts.isEmpty) {
          homeProducts = await ShopService.getFeaturedProducts(perPage: 4);
          homeProductTitle = '推荐商品';
        }
      } catch (_) {
        homeProducts = [];
      }

      if (mounted) {
        setState(() {
          _ads = ads;
          _homeProducts = homeProducts;
          _homeProductTitle = homeProductTitle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12.h),
            _buildSearchBar(),
            if (_ads.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildAdsBanner(),
            ],
            if (_homeProducts.isNotEmpty) ...[
              _buildSectionHeader(
                title: _homeProductTitle,
                actionText: '查看更多',
                onAction: _openProductListTab,
              ),
              _buildProductRail(_homeProducts),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final fillColor = isDark ? theme.colorScheme.surface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black38;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            Icon(Icons.search, size: 18.w, color: hintColor),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _openSearchResults,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: '搜索商品',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: hintColor,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openSearchResults(_searchController.text),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  size: 20.w,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            AbsCarousel(
              items: _ads,
              aspectRatio: 1.5,
              autoPlay: true,
              clipInside: true,
              domainPrefix: HttpService.domain,
              onTap: (_) => _openProductListTab(),
            ),
            Positioned(
              left: 16.w,
              bottom: 16.h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openProductListTab,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward,
                            size: 16.w,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
      child: Row(
        children: [
          Container(
            width: 7.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD24A),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.w,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductRail(List<Product> products) {
    final visibleProducts = products.take(4).toList(growable: false);

    return SizedBox(
      height: 230.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: visibleProducts.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final product = visibleProducts[index];
          return SizedBox(
            width: 150.w,
            child: ProductCard(
              product: product,
              onTap: () => _navigateToProduct(product),
            ),
          );
        },
      ),
    );
  }

  void _navigateToProduct(Product product) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );

    if (result == 'cart' && mounted) {
      final shopMainState =
          context.findAncestorStateOfType<ShopMainPageState>();
      shopMainState?.switchToTab(3);
    }
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.w,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            SizedBox(height: 16.h),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? '',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearchResults(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    FocusScope.of(context).unfocus();
    _searchController.clear();
    final shopMainState = context.findAncestorStateOfType<ShopMainPageState>();
    if (shopMainState != null) {
      shopMainState.openProductListTab(searchQuery: trimmed);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListPage(searchQuery: trimmed),
      ),
    );
  }

  void _openProductListTab() {
    final shopMainState = context.findAncestorStateOfType<ShopMainPageState>();
    if (shopMainState == null) return;
    shopMainState.openProductListTab();
  }
}
