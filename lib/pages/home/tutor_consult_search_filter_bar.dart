import 'package:flutter/material.dart';

/// 筛选参数模型
class TutorConsultSearchFilterParams {
  String keyword;
  String? gender;
  String? location;
  String? status;
  String? level;
  double experienceYearsStart;
  double experienceYearsEnd;
  double priceStart;
  double priceEnd;

  TutorConsultSearchFilterParams({
    this.keyword = '',
    this.gender,
    this.location,
    this.status,
    this.level,
    this.experienceYearsStart = 1,
    this.experienceYearsEnd = 50,
    this.priceStart = 0,
    this.priceEnd = 100,
  });

  void reset() {
    keyword = '';
    gender = null;
    location = null;
    status = null;
    level = null;
    experienceYearsStart = 1;
    experienceYearsEnd = 50;
    priceStart = 0;
    priceEnd = 100;
  }
}

/// Label + Value 类型
class LabelValue {
  final String label;
  final String value;
  const LabelValue(this.label, this.value);
}

/// 搜索 + 筛选栏组件
class TutorConsultSearchFilterBar extends StatefulWidget {
  final ValueChanged<TutorConsultSearchFilterParams> onSearch;

  const TutorConsultSearchFilterBar({super.key, required this.onSearch});

  @override
  State<TutorConsultSearchFilterBar> createState() =>
      _TutorConsultSearchFilterBarState();
}

class _TutorConsultSearchFilterBarState
    extends State<TutorConsultSearchFilterBar>
    with SingleTickerProviderStateMixin {
  final TutorConsultSearchFilterParams _params =
  TutorConsultSearchFilterParams();

  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
        widget.onSearch(_params); // 失焦立即搜索
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

  void _showFilterPanel() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material( // 透明材质，保留水波/文字等效果
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // 背景遮罩（可点击关闭）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideFilterPanel, // ← 点空白处关闭
                child: Container(color: Colors.black54),
              ),
              // 顶部下滑面板
              Align(
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _animation,
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
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
                                      padding: const EdgeInsets.all(12),
                                      child: FilterPanel(
                                        params: _params,
                                        onChanged: () => setStateOverlay(() {}),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.white,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _params.reset();
                                              _controller.clear();
                                              // 如不想清空即搜索，删掉下一行
                                              widget.onSearch(_params);
                                              _hideFilterPanel(); // ← 清空也关闭
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey[300],
                                            ),
                                            child: const Text(
                                              "清空",
                                              style: TextStyle(color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              widget.onSearch(_params);
                                              _hideFilterPanel(); // ← 确定后关闭
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFFFFC107),
                                            ),
                                            child: const Text(
                                              "确定",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
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
    // 收起键盘
    FocusScope.of(context).unfocus();

    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final borderColor = isDark ? theme.dividerColor : Colors.black;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark ? Colors.white60 : Colors.grey,
      fontSize: 12,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: isDark ? Colors.white70 : Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      cursorColor: theme.colorScheme.primary,
                      onChanged: (val) => _params.keyword = val,
                      onSubmitted: (_) => widget.onSearch(_params),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "搜索姓名查询~",
                        hintStyle: hintStyle,
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
          const SizedBox(width: 10),
          TextButton(
            onPressed: _showFilterPanel,
            child: Text(
              "筛选",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 筛选面板
class FilterPanel extends StatelessWidget {
  final TutorConsultSearchFilterParams params;
  final VoidCallback onChanged;

  const FilterPanel({super.key, required this.params, required this.onChanged});

  final List<LabelValue> genders = const [
    LabelValue("男", "2"),
    LabelValue("女", "1"),
  ];

  final List<LabelValue> locations = const [
    LabelValue("全球", "全球"),
    LabelValue("北美洲", "北美洲"),
    LabelValue("大洋洲", "大洋洲"),
    LabelValue("亚洲", "亚洲"),
    LabelValue("南美洲", "南美洲"),
    LabelValue("南极洲", "南极洲"),
    LabelValue("欧洲", "欧洲"),
    LabelValue("非洲", "非洲"),
  ];

  final List<LabelValue> statuses = const [
    LabelValue("水晶", "水晶"),
    LabelValue("祖母绿", "祖母绿"),
    LabelValue("钻石", "钻石"),
  ];

  final List<LabelValue> levels = const [
    LabelValue("启蒙老师", "1"),
    LabelValue("大宗导师", "2"),
    LabelValue("传承导师", "3"),
  ];

  Widget _buildGridOptions(
      BuildContext context, {
        required List<LabelValue> items,
        required String? selected,
        required ValueChanged<String> onSelect,
      }) {
    double itemWidth = (MediaQuery.of(context).size.width - 130) / 3;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: items.map((item) {
        final isSelected = item.value == selected;
        return GestureDetector(
          onTap: () {
            onSelect(isSelected ? '' : item.value);
            onChanged();
          },
          child: Container(
            width: itemWidth,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFFFC107) : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRow(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required BuildContext context,
    required double min,
    required double max,
    required double start,
    required double end,
    required ValueChanged<RangeValues> onChanged,
    String? unit,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // 轨道颜色：中间橙色、两端白色
        activeTrackColor: Color(0xFFFFC107),
        inactiveTrackColor: Colors.white,
        trackHeight: 4,

        // 拇指（两端按钮）白色 + 轻微阴影更清晰
        thumbColor: Colors.white,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 9,
          elevation: 1.5,
          pressedElevation: 3,
        ),

        // 按下时的外圈
        overlayColor: Colors.orange.withOpacity(0.15),

        // 轨道形状（可选）
        // rangeTrackShape: const RectangularRangeSliderTrackShape(),
      ),
      child: Column(
        children: [
          RangeSlider(
            min: min,
            max: max,
            values: RangeValues(start, end),
            onChanged: onChanged,
          ),
          Text(
            "${start.toInt()}${unit ?? ''} - ${end.toInt()}${unit ?? ''}",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(
          "性别",
          _buildGridOptions(
            context,
            items: genders,
            selected: params.gender,
            onSelect: (v) => params.gender = v.isEmpty ? null : v,
          ),
        ),
        _buildRow(
          "地点",
          _buildGridOptions(
            context,
            items: locations,
            selected: params.location,
            onSelect: (v) => params.location = v.isEmpty ? null : v,
          ),
        ),
        _buildRow(
          "地位",
          _buildGridOptions(
            context,
            items: statuses,
            selected: params.status,
            onSelect: (v) => params.status = v.isEmpty ? null : v,
          ),
        ),
        _buildRow(
          "级别",
          _buildGridOptions(
            context,
            items: levels,
            selected: params.level,
            onSelect: (v) => params.level = v.isEmpty ? null : v,
          ),
        ),
        _buildRow(
          "年限",
          _buildRangeSlider(
            context: context,
            min: 1,
            max: 50,
            start: params.experienceYearsStart,
            end: params.experienceYearsEnd,
            onChanged: (val) {
              params.experienceYearsStart = val.start;
              params.experienceYearsEnd = val.end;
              onChanged();
            },
          ),
        ),
        _buildRow(
          "价格",
          _buildRangeSlider(
            context: context,
            min: 0,
            max: 100,
            start: params.priceStart,
            end: params.priceEnd,
            onChanged: (val) {
              params.priceStart = val.start;
              params.priceEnd = val.end;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
