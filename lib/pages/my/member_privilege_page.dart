import 'package:auto_size_text/auto_size_text.dart';
import 'package:const_calc/dto/order.dart';
import 'package:const_calc/dto/vip_purview.dart';
import 'package:const_calc/services/my_service.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:flutter/material.dart';

import '../../dto/user.dart';
import '../../dto/vip_fee.dart';
import '../../services/stripe_payment_service.dart';
import '../../util/http_util.dart';

class MemberPrivilegePage extends StatefulWidget {
  const MemberPrivilegePage({super.key});

  @override
  State<MemberPrivilegePage> createState() => _MemberPrivilegePageState();
}

class _MemberPrivilegePageState extends State<MemberPrivilegePage> {
  /// 轮播卡片索引：0=基础 1=精英 2=至尊
  int _currentIndex = 0;

  // 精英/至尊的“当前选中的价格卡片”索引（互斥）
  int _selectedEliteIndex = 0;
  int _selectedSupremeIndex = 0;

  List<VipPurview> vipPurviewList = [];
  User? userInfo;

  // 精英/至尊卡片数据
  final List<PriceCard> _eliteCards = [];
  final List<PriceCard> _supremeCards = [];
  final ScrollController _hScroll = ScrollController();

  static const vipMapper = {1: '基础', 2: '精英', 3: '至尊'};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    UserService.clearCache(); // 清缓存，获取最新的，要不后台改了vip看不到
    await _initUserInfo();
    _findVipPurviewList();
    _initVip2FeeInfo();
    _initVip3FeeInfo();
  }

  int _indexFromVip(int vipLevelId) {
    final idx = vipLevelId - 1;
    return idx.clamp(0, 2);
  }

  int _defaultSelectedIndex(List<PriceCard> cards) {
    final i = cards.indexWhere((c) => c.showTag);
    return i >= 0 ? i : 0;
  }

  /// 判断是否应该显示“升级区块”
  ///
  /// 显示条件：
  /// 1. 当前卡片等级 >= 当前会员等级
  /// 2. 当前卡片不是基础卡（cardLevel != 1）
  ///
  /// [index] 卡片的索引（0=基础卡，1=精英卡，2=至尊卡）
  ///
  /// 返回： true 表示应显示价格卡片 false 表示不显示价格卡片
  bool _shouldShowUpgradeSectionForIndex(int index) {
    final cardLevel = index + 1; // 0/1/2 → 1/2/3
    final currentLevel = userInfo?.vipLevelId ?? 1;

    // 基础卡片直接不显示
    if (cardLevel == 1) return false;

    // 等于或高于当前等级才显示
    return cardLevel >= currentLevel;
  }

  /// 计算折扣金额
  double _calculateRemainingNum(int remainingDays, Order? order) {
    if (remainingDays > 0 && order != null) {
      final originalAmount = double.tryParse(order.originalAmount) ?? 0;
      final vipTime = double.tryParse(order.vipTime.toString()) ?? 1; // 避免/0
      final dailyPrice = originalAmount / vipTime;
      final remain = remainingDays * dailyPrice;
      return remain < 0 ? 0 : remain.roundToDouble();
    }
    return 0;
  }

  /// 当前可抵扣金额
  double _currentDiscountAmount() {
    int remainingDay = 0;
    if (userInfo?.vipSubscriptionEnd != null) {
      final now = DateTime.now();
      remainingDay = DateTime.parse(
        userInfo!.vipSubscriptionEnd,
      ).difference(now).inDays;
    }
    return _calculateRemainingNum(remainingDay, userInfo?.order);
  }

  /// 获取 vip 提示
  Widget _buildVipTipWidget() {
    int remainingDay = 0;
    if (userInfo != null && userInfo?.vipSubscriptionEnd != null) {
      final now = DateTime.now();
      final end = DateTime.parse(userInfo!.vipSubscriptionEnd.trim());
      remainingDay = end.difference(now).inDays;
      if (remainingDay < 0) remainingDay = 0; // 过期按 0 天处理
    }

    if (userInfo == null) {
      return const SizedBox.shrink();
    }

    final vipLevelId = userInfo?.vipLevelId;
    final vipName = vipMapper[vipLevelId] ?? '';
    final vipDate = userInfo?.vipDate ?? '';
    final discountStr = _calculateRemainingNum(
      remainingDay,
      userInfo?.order,
    ).toStringAsFixed(0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontWeight: FontWeight.w700,
    );
    final valueStyle = TextStyle(color: isDark ? Colors.white60 : const Color(0xFF999999));

    // 组装 "当前会员: 会员名(到期日)" 的括号形式
    final List<InlineSpan> memberPart = [
      TextSpan(text: '当前会员: ', style: labelStyle),
      TextSpan(text: vipName, style: valueStyle),
      if (vipLevelId != 1 && vipDate.isNotEmpty) ...[
        TextSpan(text: '(', style: valueStyle), // 括号用浅灰以减弱噪声
        TextSpan(text: vipDate, style: valueStyle),
        TextSpan(text: ')', style: valueStyle),
      ],
    ];

    // 基础会员仅显示“当前会员: xxx”
    if (vipLevelId == 1) {
      return AutoSizeText.rich(
        TextSpan(children: memberPart),
        maxLines: 1,
        minFontSize: 10,
        stepGranularity: 0.5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        // ✅ 居中
        presetFontSizes: const [14, 13, 12, 11, 10],
      );
    }

    // 其他等级：追加 "• 剩余天数: X天 • 可折扣: $Y"
    final spans = <InlineSpan>[
      ...memberPart,
      TextSpan(text: ', ', style: labelStyle),
      TextSpan(text: '剩余天数: ', style: labelStyle),
      TextSpan(text: '$remainingDay天', style: valueStyle),
      TextSpan(text: ', ', style: labelStyle),
      TextSpan(text: '可折扣: ', style: labelStyle),
      TextSpan(text: '\$$discountStr', style: valueStyle),
    ];

    return AutoSizeText.rich(
      TextSpan(children: spans),
      maxLines: 1,
      minFontSize: 10,
      stepGranularity: 0.5,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      // ✅ 居中
      presetFontSizes: const [14, 13, 12, 11, 10],
    );
  }

  Future<void> _initUserInfo() async {
    final user = await UserService().getUserInfo();
    if (!mounted) return;
    setState(() {
      userInfo = user;
      _currentIndex = _indexFromVip(
        userInfo?.vipLevelId ?? 1,
      ); // 1->0, 2->1, 3->2
    });
  }

  Future<void> _findVipPurviewList() async {
    final vpList = await HttpUtil.request<List<VipPurview>?>(
      () => MyService.getVipPurview(),
      context,
      () => mounted,
    );
    if (!mounted || vpList == null) return;
    setState(() => vipPurviewList = vpList);
  }

  /// 过滤套餐
  List<VipFee> _filterVipFeesWithFallback({
    required List<VipFee> fees,
    required double remainingNum,
    required Order? order,
  }) {
    if (fees.isEmpty) return [];

    bool keep(VipFee f) {
      if (userInfo?.vipTime == -1 && userInfo?.vipLevelId == f.vipLevelId)
        return false;
      final priceHigher = (f.price - remainingNum) > 0; // 只保留需要补差价的
      return priceHigher;
    }

    final filtered = fees.where(keep).toList();
    if (filtered.isNotEmpty) return filtered;

    return [];
  }

  /// 初始化精英会员费用（过滤 + 兜底 + 价格格式化）
  Future<void> _initVip2FeeInfo() async {
    final vip2Fee = await HttpUtil.request<List<VipFee>?>(
      () => MyService.getFeeByVipId(vipLevelId: '2'),
      context,
      () => mounted,
    );
    if (!mounted || vip2Fee == null) return;

    // 可抵扣金额
    final remainNum = _currentDiscountAmount();

    final filtered = _filterVipFeesWithFallback(
      fees: vip2Fee,
      remainingNum: remainNum,
      order: userInfo?.order,
    );

    final tmp = <PriceCard>[];
    for (final f in filtered) {
      tmp.add(
        PriceCard(
          title: f.name,
          price: f.price.toStringAsFixed(2),
          amount: f.price,
          // 用于折扣计算
          subText: f.describe,
          showTag: tmp.isEmpty,
          // 第一项默认推荐
          vipTime: f.vipTime,
        ),
      );
    }

    setState(() {
      _eliteCards
        ..clear()
        ..addAll(tmp);
      _selectedEliteIndex = _defaultSelectedIndex(_eliteCards);
    });
  }

  /// 初始化至尊会员费用（过滤 + 兜底 + 价格格式化）
  Future<void> _initVip3FeeInfo() async {
    final vip3Fee = await HttpUtil.request<List<VipFee>?>(
      () => MyService.getFeeByVipId(vipLevelId: '3'),
      context,
      () => mounted,
    );
    if (!mounted || vip3Fee == null) return;

    final remainNum = _currentDiscountAmount();

    final filtered = _filterVipFeesWithFallback(
      fees: vip3Fee,
      remainingNum: remainNum,
      order: userInfo?.order,
    );

    final tmp = <PriceCard>[];
    for (final f in filtered) {
      tmp.add(
        PriceCard(
          title: f.name,
          price: f.price.toStringAsFixed(2),
          amount: f.price,
          // 用于折扣计算
          subText: f.describe,
          showTag: tmp.isEmpty,
          vipTime: f.vipTime,
        ),
      );
    }

    setState(() {
      _supremeCards
        ..clear()
        ..addAll(tmp);
      _selectedSupremeIndex = _defaultSelectedIndex(_supremeCards);
    });
  }

  void _resetSelectionForIndex(int index) {
    if (index == 1) {
      _selectedEliteIndex = _defaultSelectedIndex(_eliteCards);
    } else if (index == 2) {
      _selectedSupremeIndex = _defaultSelectedIndex(_supremeCards);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // 带结果返回
        return false; // 阻止默认 pop（因为上面已手动 pop）
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '会员权益',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          centerTitle: true,
          backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0.5,
          leading: BackButton(onPressed: () => Navigator.pop(context, true)),
        ),
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildSwiper(),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardTheme.color : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.13),
                        offset: const Offset(0, -5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentIndex == 0)
                        _buildSectionTitle('基础会员', showVipTip: true),

                      if (_currentIndex == 1) ...[
                        if (_shouldShowUpgradeSectionForIndex(_currentIndex))
                          _buildVipSection(
                            title: '精英会员',
                            cards: _eliteCards,
                            selectedIndex: _selectedEliteIndex,
                            onSelect: (i) =>
                                setState(() => _selectedEliteIndex = i),
                          )
                        else
                          _buildSectionTitle('精英会员', showVipTip: true),
                      ],

                      if (_currentIndex == 2) ...[
                        if (_shouldShowUpgradeSectionForIndex(_currentIndex))
                          _buildVipSection(
                            title: '至尊会员',
                            cards: _supremeCards,
                            selectedIndex: _selectedSupremeIndex,
                            onSelect: (i) =>
                                setState(() => _selectedSupremeIndex = i),
                          )
                        else
                          _buildSectionTitle('至尊会员', showVipTip: true),
                      ],

                      _buildPrivilegeTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 标题 + 可选 vipTip
  Widget _buildSectionTitle(String title, {bool showVipTip = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
              color: Colors.amber,
            ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        if (showVipTip) ...[
          const SizedBox(height: 8),
          _buildVipTipWidget(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// 升级区块（价格卡横滑 + 支付按钮；无卡时空态）
  Widget _buildVipSection({
    required String title,
    required List<PriceCard> cards,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (cards.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, showVipTip: true),
          const SizedBox(height: 12),
          _emptyUpgrade('暂无可升级套餐，可能因剩余可抵扣金额较高或已是会员套餐的最高档'),
          const SizedBox(height: 12),
        ],
      );
    }

    // 动态计算横滑容器高度，适配字体放大，避免溢出
    final scale = MediaQuery.of(context).textScaleFactor;
    final base = 140.0;
    final listHeight = (base * (scale > 1.0 ? (0.9 + 0.2 * scale) : 1.0)).clamp(
      140.0,
      180.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, showVipTip: true),

        // 横向滑动 + 自适应卡片宽度
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE6E6E6)), // 浅灰色框线
          ),
          padding: const EdgeInsets.symmetric(vertical: 4), // 轻微内边距，让卡片不贴边
          child: Column(
            children: [
              // 滚动区域
              LayoutBuilder(
                builder: (context, constraints) {
                  const edge = 8.0; // 两侧留白（边框内）
                  const gap = 8.0; // 卡片间距
                  const visible = 3; // 一屏期望显示 3 张

                  final usable =
                      constraints.maxWidth - edge * 2 - gap * (visible - 1);
                  final cardWidth = (usable / visible).clamp(100.0, 9999.0);

                  return SizedBox(
                    height: listHeight,
                    child: (cards.length < 3)
                        // ===== 少于 3 个：用 Row 居中 =====
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: edge,
                            ),
                            child: Align(
                              alignment: Alignment.center, // 整体居中
                              child: SizedBox(
                                // 计算精确总宽度：N * cardWidth + (N-1) * gap
                                width: cards.isEmpty
                                    ? 0
                                    : cards.length * cardWidth +
                                          (cards.length - 1) * gap,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < cards.length; i++) ...[
                                      SizedBox(
                                        width: cardWidth,
                                        child: _buildVipCard(
                                          title: cards[i].title,
                                          price: cards[i].price,
                                          subText: cards[i].subText,
                                          isRecommended: cards[i].showTag,
                                          isSelected: i == selectedIndex,
                                          onTap: () => onSelect(i),
                                          priceColor: cards[i].priceColor,
                                          textColor: cards[i].textColor,
                                        ),
                                      ),
                                      if (i != cards.length - 1)
                                        const SizedBox(width: gap),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        // ===== 3 个及以上：维持原本的可滚动列表 =====
                        : ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              scrollbars: false,
                            ),
                            child: ListView.separated(
                              controller: _hScroll,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: edge,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: cards.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: gap),
                              itemBuilder: (context, i) {
                                final c = cards[i];
                                return SizedBox(
                                  width: cardWidth,
                                  child: _buildVipCard(
                                    title: c.title,
                                    price: c.price,
                                    subText: c.subText,
                                    isRecommended: c.showTag,
                                    isSelected: i == selectedIndex,
                                    onTap: () => onSelect(i),
                                    priceColor: c.priceColor,
                                    textColor: c.textColor,
                                  ),
                                );
                              },
                            ),
                          ),
                  );
                },
              ),

              // 滑动指示（卡片下方）
              if (cards.length > 3) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.swipe, size: 14, color: Color(0xFF9E9E9E)),
                          SizedBox(width: 4),
                          Text(
                            '左右滑动查看更多',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 14),
                          SizedBox(width: 4),
                          Text(
                            '左右没有更多了',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 按钮联动：应付 = 选中套餐原价 - 折扣
        Builder(
          builder: (_) {
            final selected = cards[selectedIndex];
            final discount = _currentDiscountAmount();
            final payable = (selected.amount - discount);
            final finalPay = (payable > 0 ? payable : 0.0).toStringAsFixed(2);

            // 基础=购买；精英=升级（在精英页不显示升级区，至尊页才显示）
            final action = ((userInfo?.vipLevelId ?? 1) <= 1) ? '购买' : '升级';
            return _buildPayButton(
              label: '$action${selected.title}', // 购买1年 / 升级5年
              priceText: '$finalPay\$', // 折后应付
              onTap: () {
                String vipName = '';
                String vipLevelId = '';
                if (_currentIndex == 1) {
                  vipName = '精英';
                  vipLevelId = '2';
                } else if (_currentIndex == 2) {
                  vipName = '至尊';
                  vipLevelId = '3';
                }
                StripePaymentService.pay(
                  vipLevelId: vipLevelId,
                  currency: 'usd',
                  vipTime: selected.vipTime.toString(),
                  vipName: vipName,
                  vipDate: selected.title,
                  amount: finalPay.toString(),
                  originalAmount: selected.amount.toString(),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _emptyUpgrade(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFEDEDED)),
      ),
      child: Text(text, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
    );
  }

  /// 单个价格卡片（点击选择 + 选中高亮 + 推荐角标 + 副文案对齐 + 自适应高度）
  Widget _buildVipCard({
    required String title,
    required String price,
    String? subText,
    bool isRecommended = false,
    required bool isSelected,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color priceColor = Colors.black,
    Color borderColor = const Color(0xFFE0E0E0),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isSelected
        ? (isDark ? const Color(0xFF4A4020) : const Color(0xFFFFF1C1))
        : (isDark ? const Color(0xFF3A3A3A) : Colors.white);
    final Color outline = isSelected
        ? const Color(0xFFFFE089)
        : (isDark ? Colors.white24 : borderColor);
    final Color cardTextColor = isDark ? Colors.white : textColor;
    final Color cardPriceColor = isDark ? const Color(0xFFFFD54F) : priceColor;

    return Padding(
      padding: const EdgeInsets.all(6), // 🟢 卡片整体的内边距
      child: SizedBox.expand(
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outline, width: 1),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    // 🟢 卡片内容的内边距
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: cardTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: price, // 价格部分
                                style: TextStyle(
                                  fontSize: 24,
                                  color: cardPriceColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' \$', // 美元符号（前面加空格可分隔）
                                style: TextStyle(
                                  fontSize: 14, // ✅ 小于价格字体
                                  color: cardPriceColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 16,
                          child: (subText != null && subText.isNotEmpty)
                              ? Text(
                                  subText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white60 : Colors.grey,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isRecommended)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '推荐',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 支付按钮（联动当前选中卡片的应付价&文案）
  Widget _buildPayButton({
    required String label, // 如：购买1年 / 升级5年
    required String priceText, // 如：$259.00（折后）
    required VoidCallback onTap, // 点击事件
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24), // 点击效果圆角
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/icons/paybtn.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              AutoSizeText(
                '$priceText  $label会员',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 10,
                // 最小缩到 10
                maxFontSize: 14,
                // 最大就是原来的 14
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivilegeTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final zebraEven = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final zebraOdd = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F3F3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('会员权益对比'),
        const SizedBox(height: 12),
        _tableHeader([
          _headerCell('权限'),
          _headerCell('基础会员'),
          _headerCell('精英会员'),
          _headerCell('至尊会员'),
        ]),
        for (int i = 0; i < vipPurviewList.length; i++)
          _dataRow(
            index: i,
            evenColor: zebraEven,
            oddColor: zebraOdd,
            cells: [
              _dataCell(
                vipPurviewList[i].purviewName,
                note: vipPurviewList[i].purviewNotes,
              ),
              _dataCell(vipPurviewList[i].baseVipKey),
              _dataCell(vipPurviewList[i].elitistVipKey),
              _dataCell(vipPurviewList[i].supremeVipKey),
            ],
          ),

        // ✅ 左下角提示文字
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "* 一次必须购买至少12个月或以上才能激活该权益\n** 优惠不包含已折扣的商品如季度打折等等",
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(List<Widget> cells) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF4A4A4A) : Colors.grey.shade300,
      child: Row(children: cells.map((c) => Expanded(child: c)).toList()),
    );
  }

  Widget _dataRow({
    required int index,
    required List<Widget> cells,
    Color? evenColor,
    Color? oddColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultEven = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final defaultOdd = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F3F3);

    final bg = index.isOdd
        ? (oddColor ?? defaultOdd)
        : (evenColor ?? defaultEven);
    return Container(
      color: bg,
      child: Row(children: cells.map((c) => Expanded(child: c)).toList()),
    );
  }

  /// 格式化显示文本：999 或 999次 显示为"无限"
  String _formatDisplayText(String text) {
    final trimmed = text.trim();
    if (trimmed == '999' || trimmed == '999次') {
      return '无限';
    }
    return text;
  }

  Widget _dataCell(String text, {Color? textColor, Color? bg, String? note}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayText = _formatDisplayText(text);
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? (isDark ? Colors.white : Colors.black),
            ),
            textAlign: TextAlign.center,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // —— 轮播 —— //
  Widget _buildSwiper() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenHeight = MediaQuery.of(context).size.height;
    final banners = [
      'assets/icons/vv1.png',
      'assets/icons/vv2.png',
      'assets/icons/vv3.png',
    ];

    return Container(
      height: screenHeight * 0.66,
      width: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/icons/bgmmm.png',
              fit: BoxFit.cover,
              height: screenHeight * 0.17,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: ValueKey('swiper-$_currentIndex'),
              height: screenHeight * 0.52, // Swiper 高度占 42%
              child: _SimpleSwiper(
                banners: banners,
                initialIndex: _currentIndex,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _resetSelectionForIndex(index);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// —— 数据类：价格卡片 —— //
class PriceCard {
  final String title; // 标题
  final String price; // 价格文案（已含 $ 和格式化）
  final double amount; // 原始金额（用于折扣计算）
  final String? subText; // 副文案
  final bool showTag; // 是否显示“推荐”标签
  final Color priceColor; // 价格颜色
  final Color textColor; // 标题颜色
  final int vipTime; // vip时间

  const PriceCard({
    required this.title,
    required this.price,
    required this.amount,
    required this.vipTime,
    this.subText,
    this.showTag = false,
    this.priceColor = Colors.black,
    this.textColor = Colors.black,
  });
}

// —— 简易轮播：支持 initialIndex —— //
class _SimpleSwiper extends StatefulWidget {
  final List<String> banners;
  final Function(int)? onPageChanged;
  final int initialIndex;

  const _SimpleSwiper({
    required this.banners,
    this.onPageChanged,
    this.initialIndex = 0,
  });

  @override
  State<_SimpleSwiper> createState() => _SimpleSwiperState();
}

class _SimpleSwiperState extends State<_SimpleSwiper> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      viewportFraction: 0.5,
      initialPage: _currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16), // 想加多少自己调
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            // 防止放大被裁剪
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  // 计算与当前页的距离
                  double distance = 0;
                  if (_pageController.position.haveDimensions) {
                    final page =
                        _pageController.page ??
                        _pageController.initialPage.toDouble();
                    distance = (page - index).abs();
                  } else {
                    distance = (index - _currentIndex).abs().toDouble();
                  }

                  // 距离越大，缩放越小（0.8 ~ 1.0）
                  // 用个非线性衰减让边上更小些，中心更突出
                  final t = (1 - distance).clamp(0.0, 1.0);
                  final scale = 0.85 + 0.2 * Curves.easeOut.transform(t);
                  final translateY =
                      -8 * Curves.easeOut.transform(t); // 选中项微微上移

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 742 / 1168,
                  child: SizedBox.expand(
                    // 让内部内容宽度占满
                    child: Image.asset(
                      widget.banners[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -10,
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _currentIndex == index
                          ? (isDark ? const Color(0xFFFFD54F) : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
