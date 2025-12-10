import 'package:const_calc/dto/library_radical.dart';
import 'package:flutter/material.dart';

import '../../dto/library_character.dart';
import '../../services/information_service.dart';
import '../../util/http_util.dart';
import '../my/member_tip.dart';
import 'card_data.dart';
import 'five_elements_card_widget.dart';
import 'number_card_widget.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _selectedIndex = 0;
  final List<String> _tabs = ['主性格说明', '81组数字说明', '五行总览', '边旁部首'];
  final Map<int, String> vipPubMapper = {
    // vip权限控制
    0: '主性格',
    1: '81组数字',
    2: '五行总览',
  };

  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _pageIndex = 1;
  final int _pageSize = 10;
  final List<CardData> _cardDataList = [];

  // 当前选中的按钮值
  String? _selectedRadicalButton;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchTextController.text.isNotEmpty) {
        // ✅ 失去焦点时触发逻辑
        _pageIndex = 1;
        _hasMore = true;
        _cardDataList.clear();
        _loadData();
      }
    });

    _loadData(); // 首次加载
  }

  /// ✅ 加载数据（分页）
  Future<void> _loadData() async {
    setState(() => _isLoadingMore = true);
    List<CardData> cardDataListTmp = [];
    if ([0, 1].contains(_selectedIndex)) {
      final List<LibraryCharacter>? recordList =
          await HttpUtil.request<List<LibraryCharacter>?>(
            () => InformationService.getLibraryCharacterList(
              pageNo: _pageIndex.toString(),
              pageSize: _pageSize.toString(),
              type: _selectedIndex == 0 ? 'sex' : '',
              keywords: _searchTextController.text,
              brush: '',
            ),
            context,
            () => mounted,
          );
      cardDataListTmp = recordList?.map((e) => e.toItem()).toList() ?? [];
    } else if (_selectedIndex == 2) {
      final List<LibraryCharacter>? recordList =
          await HttpUtil.request<List<LibraryCharacter>?>(
            () => InformationService.getLibraryElementsList(
              pageNo: _pageIndex.toString(),
              pageSize: _pageSize.toString(),
              keywords: _searchTextController.text,
            ),
            context,
            () => mounted,
          );
      cardDataListTmp = recordList?.map((e) => e.toItem()).toList() ?? [];
    } else if (_selectedIndex == 3) {
      final List<LibraryRadical>? recordList =
          await HttpUtil.request<List<LibraryRadical>?>(
            () => InformationService.getRadicalList(
              pageNo: _pageIndex.toString(),
              pageSize: _pageSize.toString(),
              keywords: _searchTextController.text,
              brush: _selectedRadicalButton ?? '',
            ),
            context,
            () => mounted,
          );
      cardDataListTmp = recordList?.map((e) => e.toItem()).toList() ?? [];
    }

    setState(() {
      if (cardDataListTmp.isEmpty || cardDataListTmp.length < _pageSize) {
        _hasMore = false;
      }
      _cardDataList.addAll(cardDataListTmp);
      _pageIndex++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '资料库',
          style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // ✅ 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: TextField(
              controller: _searchTextController,
              focusNode: _searchFocusNode,
              cursorColor: theme.primaryColor,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: '请输入关键词',
                hintStyle: TextStyle(color: theme.hintColor),
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ 自定义按钮 TabBar
          Container(
            color: theme.cardTheme.color,
            padding: const EdgeInsets.symmetric(),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (_, index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120), // ✅ 固定宽度
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedIndex == index) return; // 已经选中就不处理

                        setState(() {
                          _selectedIndex = index;
                          _pageIndex = 1;
                          _hasMore = true;
                          _cardDataList.clear();
                        });

                        _loadData(); // 重新加载数据
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? theme.primaryColor
                            : theme.cardTheme.color,
                        foregroundColor: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodyMedium?.color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          if ([0, 1, 2].contains(_selectedIndex))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: MemberTip(
                key: ValueKey(vipPubMapper[_selectedIndex]),
                vipRightKey: vipPubMapper[_selectedIndex] ?? '',
              ),
            ),

          // ✅ 内容区
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildListTab(),
                _buildListTab(),
                _buildFiveElementsTab(),
                _buildRadicalTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 默认列表
  Widget _buildListTab() {
    final theme = Theme.of(context);

    if (_cardDataList.isEmpty) {
      return Center(
        child: Text(
          '暂无记录',
          style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color),
        ),
      );
    }

    // ✅ 独立控制器
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadData();
      }
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _cardDataList.length,
      controller: scrollController,
      itemBuilder: (context, index) {
        final item = _cardDataList[index];
        return NumberCardWidget(data: item);
      },
    );
  }

  /// 五行列表
  Widget _buildFiveElementsTab() {
    final theme = Theme.of(context);

    if (_cardDataList.isEmpty) {
      return Center(
        child: Text(
          '暂无记录',
          style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color),
        ),
      );
    }

    // ✅ 独立控制器
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadData();
      }
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _cardDataList.length,
      controller: scrollController,
      itemBuilder: (context, index) {
        final item = _cardDataList[index];
        return FiveElementsCardWidget(data: item);
      },
    );
  }

  /// 边旁列表
  Widget _buildRadicalTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 17 个按钮编号
    final List<String> buttonLabels = List.generate(
      17,
      (i) => (i + 1).toString(),
    );

    final buttonBar = Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.cardTheme.color,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: buttonLabels.length,
        itemBuilder: (context, index) {
          final label = buttonLabels[index];
          final isSelected = _selectedRadicalButton == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 64,
              height: 30,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedRadicalButton = label;
                    // ✅ 可在此触发筛选逻辑
                    _pageIndex = 1;
                    _hasMore = true;
                    _cardDataList.clear();

                    _loadData();
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? theme.primaryColor
                      : theme.cardTheme.color,
                  foregroundColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                  side: BorderSide(
                    color: isSelected ? theme.primaryColor : theme.dividerColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 6,
                  ),
                ),
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
            ),
          );
        },
      ),
    );

    // ✅ 独立控制器
    final ScrollController scrollController = ScrollController();

    // ✅ 卡片列表（空也显示按钮）
    final cardListView = _cardDataList.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '暂无记录',
                style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _cardDataList.length,
            controller: scrollController
              ..addListener(() {
                if (_cardDataList.isNotEmpty &&
                    !_isLoadingMore &&
                    _hasMore &&
                    scrollController.position.pixels ==
                        scrollController.position.maxScrollExtent) {
                  _loadData();
                }
              }),
            itemBuilder: (context, index) {
              final item = _cardDataList[index];
              return NumberCardWidget(data: item);
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buttonBar,
        const SizedBox(height: 4),
        Expanded(child: cardListView),
      ],
    );
  }
}
