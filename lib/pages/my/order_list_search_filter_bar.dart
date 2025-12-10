import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../component/bottom_date_picker.dart';

/// 统一浅灰边框
const _kBorderLight = Color(0xFFE0E0E0);
const _kBorderLightFocus = Color(0xFFBDBDBD);

/// ✅ 统一控件高度（文本 / 金额 / 日期）
const double _kFieldH = 36;

/// ✅ 统一行高倍率（略放大，避免各端被截）
const double _kLH = 1.25;

/// 常用字号（用于计算垂直内边距）
const double _kFsText = 13;
const double _kFsMoney = 12;

extension _StrBlankX on String? {
  bool get isBlank => this == null || this!.trim().isEmpty;
}

/// 参数模型
class OrderListSearchFilterParams {
  String keyword;
  String? orderSn;
  String? payEmail;
  String? payName;
  String? payTimeStart;
  String? payTimeEnd;
  String? amountStart;
  String? amountEnd;

  OrderListSearchFilterParams({
    this.keyword = '',
    this.orderSn,
    this.payEmail,
    this.payName,
    this.payTimeStart,
    this.payTimeEnd,
    this.amountStart,
    this.amountEnd,
  });

  void reset() {
    keyword = '';
    orderSn = null;
    payEmail = null;
    payName = null;
    payTimeStart = null;
    payTimeEnd = null;
    amountStart = null;
    amountEnd = null;
  }

  bool get isBlank =>
      keyword.trim().isEmpty &&
          orderSn.isBlank &&
          payEmail.isBlank &&
          payName.isBlank &&
          payTimeStart.isBlank &&
          payTimeEnd.isBlank &&
          amountStart.isBlank &&
          amountEnd.isBlank;

  bool get isNotBlank => !isBlank;

  bool get onlyFiltersBlank =>
      orderSn.isBlank &&
          payEmail.isBlank &&
          payName.isBlank &&
          payTimeStart.isBlank &&
          payTimeEnd.isBlank &&
          amountStart.isBlank &&
          amountEnd.isBlank;

  Map<String, String> toQuery() {
    final raw = {
      'keyword': keyword,
      'orderSn': orderSn,
      'payEmail': payEmail,
      'payName': payName,
      'payTimeStart': payTimeStart,
      'payTimeEnd': payTimeEnd,
      'amountStart': amountStart,
      'amountEnd': amountEnd,
    };
    final m = <String, String>{};
    raw.forEach((k, v) {
      if (!(v).isBlank) m[k] = v!.trim();
    });
    return m;
  }
}

class OrderListSearchFilterBar extends StatefulWidget {
  final ValueChanged<OrderListSearchFilterParams> onSearch;

  const OrderListSearchFilterBar({super.key, required this.onSearch});

  @override
  State<OrderListSearchFilterBar> createState() =>
      _OrderListSearchFilterBarState();
}

class _OrderListSearchFilterBarState extends State<OrderListSearchFilterBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OrderListSearchFilterParams _params = OrderListSearchFilterParams();

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
        widget.onSearch(_params);
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
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideFilterPanel,
                child: Container(color: Colors.black54),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _animation,
                  child: Container(
                    width: double.infinity,
                    height: 0.45.sh,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                                      child: _FilterPanel(
                                        params: _params,
                                        onChanged: () => setStateOverlay(() {}),
                                      ),
                                    ),
                                  ),
                                  // 底部按钮
                                  Container(
                                    padding: REdgeInsets.all(12),
                                    color: Colors.white,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 34.h,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _params.reset();
                                                _controller.clear();
                                                widget.onSearch(_params);
                                                _hideFilterPanel();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.grey[300],
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
                                                  color: Colors.black,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: SizedBox(
                                            height: 34.h,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                widget.onSearch(_params);
                                                _hideFilterPanel();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                const Color(0xFFFFC107),
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
                                                  fontSize: 14.sp,
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
    FocusScope.of(context).unfocus();
    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  int _filterCount(OrderListSearchFilterParams p) {
    int c = 0;
    if (!(p.orderSn).isBlank) c++;
    if (!(p.payEmail).isBlank) c++;
    if (!(p.payName).isBlank) c++;
    if (!(p.payTimeStart).isBlank || !(p.payTimeEnd).isBlank) c++;
    if (!(p.amountStart).isBlank || !(p.amountEnd).isBlank) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 深色模式适配
    final searchBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey;
    final borderColor = isDark ? Colors.white38 : _kBorderLight;
    final iconColor = isDark ? Colors.white54 : Colors.grey;

    final double barH = 28.h;
    final BorderRadius barRadius = BorderRadius.circular(20.r);

    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              height: barH,
              padding: REdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: barRadius,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: iconColor, size: 16.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      cursorColor: isDark ? Colors.white : Colors.grey,
                      onChanged: (val) => _params.keyword = val,
                      onSubmitted: (_) => widget.onSearch(_params),
                      style: TextStyle(fontSize: 13.sp, height: 1.1, color: textColor),
                      decoration: InputDecoration(
                        hintText: "关键字（订单名/备注/邮箱/姓名…）",
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 11.sp,
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

          // 筛选按钮
          SizedBox(
            height: barH,
            child: TextButton.icon(
              onPressed: _showFilterPanel,
              icon: Icon(
                !_params.onlyFiltersBlank ? Icons.filter_alt : Icons.tune,
                size: 16.sp,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      height: 1.1,
                    ),
                  ),
                  if (!_params.onlyFiltersBlank) SizedBox(width: 6.w),
                  if (!_params.onlyFiltersBlank)
                    Container(
                      padding:
                      REdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: const Color(0xFFFFC107),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_filterCount(_params)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFFFFC107),
                          height: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
              style: TextButton.styleFrom(
                minimumSize: Size(0, barH),
                padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: !_params.onlyFiltersBlank
                    ? (isDark ? Colors.grey[800] : const Color(0xFFFFF6DB))
                    : (isDark ? const Color(0xFF2C2C2C) : null),
                shape: RoundedRectangleBorder(
                  borderRadius: barRadius,
                  side: BorderSide(color: borderColor, width: 1),
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

/// 筛选面板（统一高度 + 防截断 + hint 居中）
class _FilterPanel extends StatefulWidget {
  final OrderListSearchFilterParams params;
  final VoidCallback onChanged;

  const _FilterPanel({required this.params, required this.onChanged});

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final TextEditingController _orderSnCtrl;
  late final TextEditingController _payEmailCtrl;
  late final TextEditingController _payNameCtrl;
  late final TextEditingController _amountStartCtrl;
  late final TextEditingController _amountEndCtrl;

  @override
  void initState() {
    super.initState();
    _orderSnCtrl = TextEditingController(text: widget.params.orderSn ?? '');
    _payEmailCtrl = TextEditingController(text: widget.params.payEmail ?? '');
    _payNameCtrl = TextEditingController(text: widget.params.payName ?? '');
    _amountStartCtrl =
        TextEditingController(text: widget.params.amountStart ?? '');
    _amountEndCtrl = TextEditingController(text: widget.params.amountEnd ?? '');
  }

  @override
  void dispose() {
    _orderSnCtrl.dispose();
    _payEmailCtrl.dispose();
    _payNameCtrl.dispose();
    _amountStartCtrl.dispose();
    _amountEndCtrl.dispose();
    super.dispose();
  }

  /// 统一装饰：用 contentPadding 控制垂直居中
  EdgeInsets _contentPaddingFor(double fontPx) {
    final fieldH = _kFieldH.h;
    final linePx = fontPx * _kLH;
    final v = ((fieldH - linePx) / 2).clamp(0, 100).toDouble();
    return EdgeInsets.symmetric(horizontal: 10.w, vertical: v + 0.5);
  }

  InputDecoration _decoration({String? hint, required double fontPx}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: _contentPaddingFor(fontPx),
      hintStyle: TextStyle(
        fontSize: fontPx,
        color: Colors.grey,
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _kBorderLight, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _kBorderLight, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _kBorderLightFocus, width: 1),
      ),
    );
  }

  Widget _row(String title, Widget right) {
    final rowH = _kFieldH.h;
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: rowH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56.w,
              height: rowH,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 6.w),
            // 右侧同样放进固定高的盒子里（避免把行撑高）
            Expanded(
              child: SizedBox(
                height: rowH,
                child: Align(
                  alignment: Alignment.centerLeft, // 右侧内容靠左，垂直居中
                  child: right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 普通文本框
  Widget _textField({
    required TextEditingController controller,
    TextInputType? type,
    String? hint,
    required void Function(String) onChanged,
  }) {
    final fs = _kFsText.sp;
    return SizedBox(
      height: _kFieldH.h,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: Colors.grey,
        keyboardType: type,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        strutStyle: const StrutStyle(
          height: _kLH,
          leading: 0,
          forceStrutHeight: true,
        ),
        style: TextStyle(fontSize: fs, color: Colors.black87),
        decoration: _decoration(hint: hint, fontPx: fs),
      ),
    );
  }

  /// 日期框：Stack + Center，绝不靠 padding，避免被截
  Widget _dateBox(
      BuildContext context, {
        required String? value,
        required VoidCallback onPick,
        required VoidCallback onClear,
      }) {
    final fs = _kFsMoney.sp;
    return InkWell(
      onTap: onPick,
      child: Container(
        height: _kFieldH.h,
        decoration: const ShapeDecoration(
          shape: OutlineInputBorder(
            borderSide: BorderSide(color: _kBorderLight, width: 1),
          ),
        ),
        child: Stack(
          children: [
            // 中间文字
            Center(
              child: Text(
                value ?? '请选择',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: value == null ? Colors.grey : Colors.black87,
                  fontSize: fs,
                ),
                strutStyle: const StrutStyle(
                  height: _kLH,
                  leading: 0,
                  forceStrutHeight: true,
                ),
              ),
            ),
            // 右侧清空
            if (value != null)
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _pickDate(
      BuildContext context, {
        required bool isStart,
        String? currentValue,
      }) async {
    DateTime? initial;
    if (currentValue != null && currentValue.trim().isNotEmpty) {
      try {
        final parts = currentValue.split('-'); // yyyy-MM-dd
        initial = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {}
    }

    BottomDatePicker.showDatePicker(
      context: context,
      initialDate: initial,
      onConfirm: (formatted, raw) {
        setState(() {
          if (isStart) {
            widget.params.payTimeStart = formatted;
          } else {
            widget.params.payTimeEnd = formatted;
          }
        });
        widget.onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;

    return Column(
      children: [
        _row(
          '订单号',
          _textField(
            controller: _orderSnCtrl,
            onChanged: (v) {
              p.orderSn = v;
              widget.onChanged();
            },
          ),
        ),
        _row(
          '支付邮箱',
          _textField(
            controller: _payEmailCtrl,
            type: TextInputType.emailAddress,
            onChanged: (v) {
              p.payEmail = v;
              widget.onChanged();
            },
          ),
        ),
        _row(
          '支付姓名',
          _textField(
            controller: _payNameCtrl,
            onChanged: (v) {
              p.payName = v;
              widget.onChanged();
            },
          ),
        ),
        _row(
          '付款时间',
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  context,
                  value: p.payTimeStart,
                  onPick: () => _pickDate(
                    context,
                    isStart: true,
                    currentValue: p.payTimeStart,
                  ),
                  onClear: () {
                    setState(() => p.payTimeStart = null);
                    widget.onChanged();
                  },
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _dateBox(
                  context,
                  value: p.payTimeEnd,
                  onPick: () => _pickDate(
                    context,
                    isStart: false,
                    currentValue: p.payTimeEnd,
                  ),
                  onClear: () {
                    setState(() => p.payTimeEnd = null);
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
        _row(
          '金额范围',
          Row(
            children: [
              Expanded(
                child: _moneyField(
                  controller: _amountStartCtrl,
                  hint: '自定义最低价',
                  onChanged: (v) {
                    p.amountStart = v;
                    widget.onChanged();
                  },
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _moneyField(
                  controller: _amountEndCtrl,
                  hint: '自定义最高价',
                  onChanged: (v) {
                    p.amountEnd = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 金额输入
  Widget _moneyField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    final fs = _kFsMoney.sp;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return SizedBox(
          height: _kFieldH.h,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            cursorColor: Colors.grey,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLines: 1,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(
              height: _kLH,
              leading: 0,
              forceStrutHeight: true,
            ),
            style: TextStyle(
              fontSize: fs,
              color: hasText ? Colors.black87 : Colors.grey,
            ),
            decoration: _decoration(hint: hint, fontPx: fs).copyWith(
              prefix: hasText
                  ? Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  '\$',
                  style: TextStyle(fontSize: fs, color: Colors.black87),
                ),
              )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
