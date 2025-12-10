import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BottomDatePicker {
  static void showDatePicker({
    required BuildContext context,
    required void Function(String formattedDate, DateTime rawDate) onConfirm,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    Color? confirmColor,
    Color cancelColor = Colors.grey,
    String dateFormat = 'yyyy-MM-dd',
    double pickerFontSize = 16,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (_) {
        return _BottomDatePickerWidget(
          onClose: () => overlayEntry.remove(),
          onConfirm: onConfirm,
          initialDate: initialDate ?? DateTime.now(),
          minDate: minDate,
          maxDate: maxDate,
          confirmColor: confirmColor ?? Theme.of(context).primaryColor,
          cancelColor: cancelColor,
          dateFormat: dateFormat,
          pickerFontSize: pickerFontSize,
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}

class _BottomDatePickerWidget extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Color confirmColor;
  final Color cancelColor;
  final String dateFormat;
  final double pickerFontSize;
  final VoidCallback onClose;
  final void Function(String formattedDate, DateTime rawDate) onConfirm;

  const _BottomDatePickerWidget({
    required this.initialDate,
    required this.onClose,
    required this.onConfirm,
    this.minDate,
    this.maxDate,
    required this.confirmColor,
    this.cancelColor = Colors.grey,
    this.dateFormat = 'yyyy-MM-dd',
    this.pickerFontSize = 16,
  });

  @override
  State<_BottomDatePickerWidget> createState() =>
      _BottomDatePickerWidgetState();
}

class _BottomDatePickerWidgetState extends State<_BottomDatePickerWidget>
    with SingleTickerProviderStateMixin {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  late FixedExtentScrollController yearController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;

  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;

    yearController = FixedExtentScrollController(
      initialItem: selectedYear - 1900,
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  List<int> _getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? Colors.white24 : const Color(0xFFE5E5E5);

    final years = List.generate(201, (i) => 1900 + i);
    final months = List.generate(12, (i) => i + 1);
    final days = _getDaysInMonth(selectedYear, selectedMonth);

    return Positioned.fill(
      child: Stack(
        children: [
          // 点击背景关闭
          GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _animation,
              child: Container(
                height: 280,
                clipBehavior: Clip.hardEdge, // ✅ 避免亚像素缝
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    // 顶部操作栏
                    // 顶部操作栏
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: bgColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _close,
                                child: Text(
                                  '取消',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : widget.cancelColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final date = DateTime(selectedYear, selectedMonth, selectedDay);
                                  final formatted = DateFormat(widget.dateFormat).format(date);
                                  widget.onConfirm(formatted, date);
                                  _close();
                                },
                                child: Text(
                                  '确认',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFFFD54F) : widget.confirmColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ✅ 分割线
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: dividerColor,
                        ),
                      ],
                    ),
                    // 中间 Picker
                    Expanded(
                      child: ColoredBox(
                        color: bgColor, // ✅ 背景与头部保持一致
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoPicker(
                                backgroundColor: bgColor,
                                // ✅ 避免色差
                                selectionOverlay: const SizedBox.shrink(),
                                // ✅ 去掉选中线
                                scrollController: yearController,
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedYear = years[index];
                                    if (selectedDay >
                                        _getDaysInMonth(
                                          selectedYear,
                                          selectedMonth,
                                        ).length) {
                                      selectedDay = _getDaysInMonth(
                                        selectedYear,
                                        selectedMonth,
                                      ).last;
                                      dayController.jumpToItem(selectedDay - 1);
                                    }
                                  });
                                },
                                children: years
                                    .map(
                                      (y) => Center(
                                        child: Text(
                                          '$y 年',
                                          style: TextStyle(
                                            fontSize: widget.pickerFontSize,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                backgroundColor: bgColor,
                                selectionOverlay: const SizedBox.shrink(),
                                scrollController: monthController,
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedMonth = months[index];
                                    if (selectedDay >
                                        _getDaysInMonth(
                                          selectedYear,
                                          selectedMonth,
                                        ).length) {
                                      selectedDay = _getDaysInMonth(
                                        selectedYear,
                                        selectedMonth,
                                      ).last;
                                      dayController.jumpToItem(selectedDay - 1);
                                    }
                                  });
                                },
                                children: months
                                    .map(
                                      (m) => Center(
                                        child: Text(
                                          '$m 月',
                                          style: TextStyle(
                                            fontSize: widget.pickerFontSize,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                backgroundColor: bgColor,
                                selectionOverlay: const SizedBox.shrink(),
                                scrollController: dayController,
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedDay = days[index];
                                  });
                                },
                                children: days
                                    .map(
                                      (d) => Center(
                                        child: Text(
                                          '$d 日',
                                          style: TextStyle(
                                            fontSize: widget.pickerFontSize,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
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
  }

  void _close() async {
    await _controller.reverse();
    widget.onClose();
  }
}
