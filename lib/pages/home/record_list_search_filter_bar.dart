import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../component/bottom_date_picker.dart';

/// 筛选参数模型
class RecordListSearchFilterParams {
  String keyword;
  String? gender; // 多选后以逗号拼接："1,2"
  String? zodiac; // 多选后以逗号拼接："鼠,牛,虎"
  String? constellation; // 多选后以逗号拼接
  String? mainTrait; // 多选后以逗号拼接
  String? birthStart;
  String? birthEnd;
  String? calcStart;
  String? calcEnd;

  RecordListSearchFilterParams({
    this.keyword = '',
    this.gender,
    this.zodiac,
    this.constellation,
    this.mainTrait,
    this.birthStart,
    this.birthEnd,
    this.calcStart,
    this.calcEnd,
  });

  void reset() {
    keyword = '';
    gender = null;
    zodiac = null;
    constellation = null;
    mainTrait = null;
    birthStart = null;
    birthEnd = null;
    calcStart = null;
    calcEnd = null;
  }

  /// 所有筛选条件都为空？
  bool get isBlank =>
      keyword.trim().isEmpty &&
      gender.isCsvBlank &&
      zodiac.isCsvBlank &&
      constellation.isCsvBlank &&
      mainTrait.isCsvBlank &&
      birthStart.isBlank &&
      birthEnd.isBlank &&
      calcStart.isBlank &&
      calcEnd.isBlank;

  /// 有任意一个条件被设置？
  bool get isNotBlank => !isBlank;

  /// 仅判断“筛选项”是否为空（不把 keyword 当筛选）
  bool get onlyFiltersBlank =>
      gender.isCsvBlank &&
      zodiac.isCsvBlank &&
      constellation.isCsvBlank &&
      mainTrait.isCsvBlank &&
      birthStart.isBlank &&
      birthEnd.isBlank &&
      calcStart.isBlank &&
      calcEnd.isBlank;
}

// --- 可复用的小工具：判空 ---
extension _StrBlankX on String? {
  /// 普通判空：null / "" / 全是空白
  bool get isBlank => this == null || this!.trim().isEmpty;

  /// CSV 判空：null / "" / 只包含逗号和空白 也算空
  bool get isCsvBlank {
    final s = this;
    if (s == null) return true;
    // 拆分后每个条目都是空白 => 视为空
    return s.split(',').every((e) => e.trim().isEmpty);
  }
}

/// 搜索 + 筛选栏组件
class RecordListSearchFilterBar extends StatefulWidget {
  final ValueChanged<RecordListSearchFilterParams> onSearch;
  final bool showMainPerson;

  const RecordListSearchFilterBar({
    super.key,
    required this.onSearch,
    required this.showMainPerson,
  });

  @override
  State<RecordListSearchFilterBar> createState() =>
      _RecordListSearchFilterBarState();
}

class _RecordListSearchFilterBarState extends State<RecordListSearchFilterBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 失焦即搜
  final RecordListSearchFilterParams _params = RecordListSearchFilterParams();

  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onSearch(_params); // 输入框失焦立即搜索
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 显示筛选面板（遮罩可点击关闭）
  void _showFilterPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelBgColor = isDark ? theme.cardTheme.color ?? const Color(0xFF2C2C2C) : Colors.white;
    final buttonBgColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final buttonTextColor = isDark ? Colors.white : Colors.black;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // 背景遮罩（点击关闭）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideFilterPanel,
                child: Container(color: Colors.black54),
              ),
              // 顶部下滑面板
              Align(
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _animation,
                  child: Container(
                    width: double.infinity,
                    height: 0.65.sh,
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setStateOverlay) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: REdgeInsets.all(12),
                                      child: FilterPanel(
                                        showMainPerson: widget.showMainPerson,
                                        params: _params,
                                        onChanged: () => setStateOverlay(() {}),
                                      ),
                                    ),
                                  ),
                                  // 底部按钮（清空/确定）
                                  Container(
                                    padding: REdgeInsets.all(12),
                                    color: panelBgColor,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 36.h,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _params.reset();
                                                _controller.clear();
                                                widget.onSearch(_params);
                                                _hideFilterPanel();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: buttonBgColor,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.r,
                                                      ),
                                                ),
                                              ),
                                              child: Text(
                                                "清空",
                                                style: TextStyle(
                                                  color: buttonTextColor,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: SizedBox(
                                            height: 36.h,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                widget.onSearch(_params);
                                                _hideFilterPanel();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFFFC107,
                                                ),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.r,
                                                      ),
                                                ),
                                              ),
                                              child: Text(
                                                "确定",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  Future<void> _hideFilterPanel() async {
    // 收起键盘，优雅关闭
    FocusScope.of(context).unfocus();
    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool _csvHasValue(String? s) =>
      s != null && s.split(',').any((e) => e.trim().isNotEmpty);

  int _filterCount(RecordListSearchFilterParams p) {
    int c = 0;
    if (_csvHasValue(p.gender)) c++;
    if (_csvHasValue(p.zodiac)) c++;
    if (_csvHasValue(p.constellation)) c++;
    if (_csvHasValue(p.mainTrait)) c++;
    if ((p.birthStart?.trim().isNotEmpty ?? false) ||
        (p.birthEnd?.trim().isNotEmpty ?? false)) {
      c++;
    }
    if ((p.calcStart?.trim().isNotEmpty ?? false) ||
        (p.calcEnd?.trim().isNotEmpty ?? false)) {
      c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white54 : Colors.grey;
    final borderColor = isDark ? Colors.white38 : Colors.black;
    final iconColor = isDark ? Colors.white54 : Colors.grey;

    // 统一的高度/圆角/边框
    final double barH = 32.h;
    final BorderRadius barRadius = BorderRadius.circular(20.r);

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 搜索框（自适应拉伸）
          Expanded(
            child: Container(
              height: barH,
              padding: REdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: barRadius,
                border: Border.all(color: borderColor, width: 1.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: iconColor, size: 18.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      cursorColor: isDark ? Colors.white : Colors.grey,
                      onChanged: (val) => _params.keyword = val,
                      onSubmitted: (_) => widget.onSearch(_params),
                      style: TextStyle(fontSize: 14.sp, height: 1.1, color: textColor),
                      decoration: InputDecoration(
                        hintText: "搜索姓名 标签 性格查询~",
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 12.sp,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // 筛选按钮（与搜索框同高/同圆角/同边框）
          SizedBox(
            height: barH, // 保证和搜索框一样高
            child: TextButton.icon(
              onPressed: _showFilterPanel,
              icon: Icon(
                !_params.onlyFiltersBlank ? Icons.filter_alt : Icons.tune,
                size: 18.sp,
                color: !_params.onlyFiltersBlank
                    ? const Color(0xFFFFC107)
                    : textColor,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "筛选",
                    style: TextStyle(
                      color: !_params.onlyFiltersBlank
                          ? const Color(0xFFFFC107)
                          : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      height: 1.1,
                    ),
                  ),
                  if (!_params.onlyFiltersBlank) SizedBox(width: 6.w),
                  if (!_params.onlyFiltersBlank)
                    Container(
                      padding: REdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: const Color(0xFFFFC107),
                          width: 1.r,
                        ),
                      ),
                      child: Text(
                        '${_filterCount(_params)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFFFC107),
                          height: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
              style: TextButton.styleFrom(
                minimumSize: Size(0, barH),
                padding: REdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: !_params.onlyFiltersBlank
                    ? (isDark ? Colors.grey[800] : const Color(0xFFFFF6DB))
                    : (isDark ? theme.cardTheme.color : null),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: BorderSide(
                    color: !_params.onlyFiltersBlank
                        ? const Color(0xFFFFC107)
                        : (isDark ? Colors.white24 : Colors.transparent), // 深色模式显示边框
                    width: 1.r,
                  ),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ========================= Panel 部分 =========================
class LabelValue {
  final String label;
  final String? value; // 允许为空
  const LabelValue(this.label, [this.value]);
}

class FilterPanel extends StatelessWidget {
  final RecordListSearchFilterParams params;
  final VoidCallback onChanged;
  final bool showMainPerson;

  const FilterPanel({
    super.key,
    required this.params,
    required this.onChanged,
    required this.showMainPerson,
  });

  // 多选项
  final List<LabelValue> genders = const [
    LabelValue("男", "2"),
    LabelValue("女", "1"),
  ];

  final List<LabelValue> zodiacs = const [
    LabelValue("鼠", "鼠"),
    LabelValue("牛", "牛"),
    LabelValue("虎", "虎"),
    LabelValue("兔", "兔"),
    LabelValue("龙", "龙"),
    LabelValue("蛇", "蛇"),
    LabelValue("马", "马"),
    LabelValue("羊", "羊"),
    LabelValue("猴", "猴"),
    LabelValue("鸡", "鸡"),
    LabelValue("狗", "狗"),
    LabelValue("猪", "猪"),
  ];

  final List<LabelValue> constellations = const [
    LabelValue("水瓶座", "水瓶座"),
    LabelValue("双鱼座", "双鱼座"),
    LabelValue("白羊座", "白羊座"),
    LabelValue("金牛座", "金牛座"),
    LabelValue("双子座", "双子座"),
    LabelValue("巨蟹座", "巨蟹座"),
    LabelValue("狮子座", "狮子座"),
    LabelValue("处女座", "处女座"),
    LabelValue("天秤座", "天秤座"),
    LabelValue("天蝎座", "天蝎座"),
    LabelValue("射手座", "射手座"),
    LabelValue("摩羯座", "摩羯座"),
  ];

  final List<LabelValue> traits = const [
    LabelValue("1", "1"),
    LabelValue("2", "2"),
    LabelValue("3", "3"),
    LabelValue("4", "4"),
    LabelValue("5", "5"),
    LabelValue("6", "6"),
    LabelValue("7", "7"),
    LabelValue("8", "8"),
    LabelValue("9", "9"),
  ];

  // ---- helpers ----
  Set<String> _toSet(String? csv) =>
      (csv == null || csv.trim().isEmpty) ? <String>{} : csv.split(',').toSet();

  String? _toCsvOrNull(Set<String> set) => set.isEmpty ? null : set.join(',');

  void _toggleCsv({
    required String? currentCsv,
    required String value,
    required void Function(String?) setter,
  }) {
    final s = _toSet(currentCsv);
    if (s.contains(value)) {
      s.remove(value);
    } else {
      s.add(value);
    }
    setter(_toCsvOrNull(s));
    onChanged();
  }

  Widget _buildGridOptions(
    BuildContext context, {
    required List<LabelValue> items,
    required String? selectedCsv, // 逗号拼接
    required ValueChanged<String?> setterCsv, // 写回逗号拼接
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedBgColor = isDark ? Colors.grey[700] : Colors.grey[200];
    final unselectedTextColor = isDark ? Colors.white : Colors.black;

    final selectedSet = _toSet(selectedCsv);
    final double itemWidth = (1.sw - 130.w) / 3; // 三列布局的近似宽度
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: items.map((item) {
        final bool isSelected =
            item.value != null && selectedSet.contains(item.value!);
        return GestureDetector(
          onTap: () {
            if (item.value == null) return;
            _toggleCsv(
              currentCsv: selectedCsv,
              value: item.value!,
              setter: setterCsv,
            );
          },
          child: Container(
            width: itemWidth,
            padding: REdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : unselectedBgColor,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 1.r,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : unselectedTextColor,
                fontSize: 12.sp,
                height: 1.2,
              ),
              strutStyle: StrutStyle(
                forceStrutHeight: true,
                height: 1.2,
                leading: 0,
                fontSize: 12, // 物理像素
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRow(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: REdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50.w,
            child: Text(
              title,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildDateRange(
    BuildContext context,
    String? start,
    String? end,
    bool isBirth,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context, true, isBirth),
            child: _buildDateBox(context, start),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context, false, isBirth),
            child: _buildDateBox(context, end),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox(BuildContext context, String? date) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[700] : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: 28.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        date ?? '请选择',
        style: TextStyle(color: textColor, fontSize: 11.sp, height: 1.2),
        strutStyle: const StrutStyle(
          forceStrutHeight: true,
          height: 1.2,
          leading: 0,
          fontSize: 11,
        ),
      ),
    );
  }

  void _pickDate(BuildContext context, bool isStart, bool isBirth) {
    BottomDatePicker.showDatePicker(
      context: context,
      onConfirm: (formatted, raw) {
        if (isBirth) {
          if (isStart) {
            params.birthStart = formatted;
          } else {
            params.birthEnd = formatted;
          }
        } else {
          if (isStart) {
            params.calcStart = formatted;
          } else {
            params.calcEnd = formatted;
          }
        }
        onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(
          context,
          '性别',
          _buildGridOptions(
            context,
            items: genders,
            selectedCsv: params.gender,
            setterCsv: (csv) => params.gender = csv,
          ),
        ),
        _buildRow(
          context,
          '生肖',
          _buildGridOptions(
            context,
            items: zodiacs,
            selectedCsv: params.zodiac,
            setterCsv: (csv) => params.zodiac = csv,
          ),
        ),
        _buildRow(
          context,
          '星座',
          _buildGridOptions(
            context,
            items: constellations,
            selectedCsv: params.constellation,
            setterCsv: (csv) => params.constellation = csv,
          ),
        ),
        if (showMainPerson) ...[
          _buildRow(
            context,
            '主性格',
            _buildGridOptions(
              context,
              items: traits,
              selectedCsv: params.mainTrait,
              setterCsv: (csv) => params.mainTrait = csv,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        _buildRow(
          context,
          '出生日期',
          _buildDateRange(context, params.birthStart, params.birthEnd, true),
        ),
        _buildRow(
          context,
          '测算日期',
          _buildDateRange(context, params.calcStart, params.calcEnd, false),
        ),
      ],
    );
  }
}
