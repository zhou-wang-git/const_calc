import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../dto/shop/shop_dto.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';
import '../../widgets/shop/shop_empty_state.dart';
import 'product_detail_page.dart';
import 'shop_main_page.dart';

/// 商品列表页
/// 支持分类筛选、搜索、排序
class ProductListPage extends StatefulWidget {
  final int? categoryId;
  final String? searchQuery;

  const ProductListPage({
    super.key,
    this.categoryId,
    this.searchQuery,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ShopSortOption {
  final String label;
  final String orderBy;
  final String order;
  final IconData? icon;

  const _ShopSortOption(this.label, this.orderBy, this.order, this.icon);
}

class _ProductListPageState extends State<ProductListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<Product> _products = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String? _searchQuery;
  double? _minPrice;
  double? _maxPrice;
  String _orderBy = 'date';
  String _order = 'desc';

  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _searchQuery = _normalizeSearch(widget.searchQuery);
    _searchController.text = _searchQuery ?? '';
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadProducts(refresh: true);
  }

  @override
  void didUpdateWidget(ProductListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchQuery = _normalizeSearch(widget.searchQuery);
      _searchController.text = _searchQuery ?? '';
      _loadProducts(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ShopService.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (_) {
      // 忽略分类加载错误
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _hasMore = true;
        _error = null;
      }
    });

    try {
      final products = await ShopService.getProducts(
        page: _page,
        perPage: 20,
        categoryId: _selectedCategoryId,
        search: _searchQuery,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        orderBy: _orderBy,
        order: _order,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _products = products;
          } else {
            _products.addAll(products);
          }
          _hasMore = products.length >= 20;
          _page++;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildSearchFilterBar(isDark),
        // 商品列表
        Expanded(
          child: _buildProductList(isDark),
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar(bool isDark) {
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black12;
    final fillColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor =
        isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black38;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42.h,
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
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _applySearch,
                      style: TextStyle(fontSize: 14.sp, color: textColor),
                      decoration: InputDecoration(
                        hintText: '搜索商品',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: hintColor,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Icon(
                          Icons.close,
                          size: 18.w,
                          color: hintColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            height: 42.h,
            child: OutlinedButton.icon(
              onPressed: _showFilterSheet,
              icon: Icon(Icons.tune, size: 17.w),
              label: Text(
                '筛选',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black87,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(bool isDark) {
    if (_error != null && _products.isEmpty) {
      return _buildErrorView(isDark);
    }

    if (_products.isEmpty && !_isLoading) {
      return _buildEmptyView(isDark);
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.7,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return ProductCard(
            product: _products[index],
            onTap: () => _navigateToProduct(_products[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_cart.svg',
      title: '暂无商品',
      subtitle: '换个关键词或筛选条件试试看。',
      actionText: '清空筛选',
      onAction: _resetFilters,
    );
  }

  Widget _buildErrorView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_error.svg',
      title: '商品加载失败',
      subtitle: '网络或商城服务可能异常，请稍后重试。',
      actionText: '重试',
      onAction: () => _loadProducts(refresh: true),
    );
  }

  void _applySearch(String value) {
    FocusScope.of(context).unfocus();
    setState(() => _searchQuery = _normalizeSearch(value));
    _loadProducts(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = null);
    _loadProducts(refresh: true);
  }

  void _resetFilters() {
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _searchQuery = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedCategoryId = null;
      _orderBy = 'date';
      _order = 'desc';
    });
    _loadProducts(refresh: true);
  }

  String? _normalizeSearch(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _applyPriceFilter() {
    setState(() {
      _minPrice = _parsePrice(_minPriceController.text);
      _maxPrice = _parsePrice(_maxPriceController.text);
    });
    _loadProducts(refresh: true);
  }

  double? _parsePrice(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sortOptions = [
      _ShopSortOption('最新', 'date', 'desc', null),
      _ShopSortOption('价格 ↑', 'price', 'asc', Icons.arrow_upward),
      _ShopSortOption('价格 ↓', 'price', 'desc', Icons.arrow_downward),
      _ShopSortOption('热门', 'popularity', 'desc', Icons.local_fire_department),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '筛选商品',
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (isDark)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42.w,
                            height: 42.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 26.w,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 34.h),
                  Text(
                    '分类',
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      _buildFilterChip(
                        label: '全部',
                        selected: _selectedCategoryId == null,
                        onSelected: () => _selectCategory(null),
                      ),
                      ..._categories.map(
                        (category) => _buildFilterChip(
                          label: category.name,
                          selected: category.id == _selectedCategoryId,
                          onSelected: () => _selectCategory(category.id),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    '价格区间',
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildPriceFilterRow(isDark),
                  SizedBox(height: 32.h),
                  Text(
                    '排序',
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSortOptionsRow(sortOptions),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
  }) {
    return SizedBox(
      height: 38.h,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color:
                isDark ? Colors.white.withValues(alpha: 0.32) : Colors.black38,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14.w, right: 8.w),
            child: Text(
              '¥',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFE9CFA2)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 36.w),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black12,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black12,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFFE9CFA2)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceFilterRow(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.w;
        final dashWidth = 10.w;
        final applyWidth = 92.w;
        final fieldWidth =
            (constraints.maxWidth - gap * 3 - dashWidth - applyWidth) / 2;
        final priceFieldWidth = fieldWidth.clamp(94.w, 160.w).toDouble();

        return Row(
          children: [
            SizedBox(
              width: priceFieldWidth,
              child: _buildPriceField(
                controller: _minPriceController,
                hintText: '最低价',
                isDark: isDark,
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: dashWidth,
              child: Text(
                '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.72)
                      : Colors.black45,
                ),
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: priceFieldWidth,
              child: _buildPriceField(
                controller: _maxPriceController,
                hintText: '最高价',
                isDark: isDark,
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: applyWidth,
              height: 38.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyPriceFilter();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: isDark
                      ? const Color(0xFFE9CFA2)
                      : Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFFE9CFA2)
                          : Theme.of(context).colorScheme.primary,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(19.r),
                  ),
                ),
                child: Text(
                  '应用',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOptionsRow(List<_ShopSortOption> sortOptions) {
    return Row(
      children: [
        for (int i = 0; i < sortOptions.length; i++) ...[
          Expanded(
            child: _buildFilterChip(
              label: sortOptions[i].label,
              icon: sortOptions[i].icon,
              compact: true,
              selected: _orderBy == sortOptions[i].orderBy &&
                  _order == sortOptions[i].order,
              onSelected: () =>
                  _selectSort(sortOptions[i].orderBy, sortOptions[i].order),
            ),
          ),
          if (i != sortOptions.length - 1) SizedBox(width: 8.w),
        ],
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg =
        isDark ? const Color(0xFFEFD3A4) : theme.colorScheme.primary;
    final unselectedBg =
        isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade100;
    final selectedText = isDark ? Colors.black87 : Colors.white;
    final unselectedText =
        isDark ? Colors.white.withValues(alpha: 0.74) : Colors.black87;
    final accent = isDark ? const Color(0xFFE9CFA2) : theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onSelected();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: compact ? 42.h : 48.h,
        padding: EdgeInsets.symmetric(horizontal: compact ? 6.w : 20.w),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black12),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (selected || icon != null) ...[
              Icon(
                selected ? Icons.check : icon,
                size: compact ? 16.w : 20.w,
                color: selected ? selectedText : accent,
              ),
              SizedBox(width: compact ? 4.w : 10.w),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 14.sp : 16.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? selectedText : unselectedText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(refresh: true);
  }

  void _selectSort(String orderBy, String order) {
    setState(() {
      _orderBy = orderBy;
      _order = order;
    });
    _loadProducts(refresh: true);
  }

  void _navigateToProduct(Product product) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );

    // 如果返回 'cart'，切换到购物车 Tab
    if (result == 'cart' && mounted) {
      final shopMainState =
          context.findAncestorStateOfType<ShopMainPageState>();
      shopMainState?.switchToTab(3);
    }
  }
}
