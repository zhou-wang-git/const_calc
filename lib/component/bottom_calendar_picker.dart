import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BottomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String format; // ✅ 根据格式判断
  final void Function(String formatted, DateTime rawDate) onConfirm;

  const BottomCalendarPicker({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.format = 'yyyy-MM-dd',
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(String formatted, DateTime rawDate) onConfirm,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String format = 'yyyy-MM-dd',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BottomCalendarPicker(
        initialDate: initialDate ?? DateTime.now(),
        firstDate: firstDate,
        lastDate: lastDate,
        format: format,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BottomCalendarPicker> createState() => _BottomCalendarPickerState();
}

class _BottomCalendarPickerState extends State<BottomCalendarPicker> {
  late DateTime _selectedDate;

  bool get _showDay => widget.format.contains('d');

  bool get _showMonth => widget.format.contains('M');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: Column(
        children: [
          // 顶部关闭
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Expanded(
            child: _showDay
                ? _buildDayPicker()
                : _showMonth
                ? _buildMonthPicker()
                : _buildYearPicker(),
          ),

          // 确认按钮
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8, // ✅ 占 80% 宽度
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFC107),
                  padding: const EdgeInsets.symmetric(vertical: 18), // ✅ 高度加大
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final formatted = DateFormat(
                    widget.format,
                  ).format(_selectedDate);
                  widget.onConfirm(formatted, _selectedDate);
                },
                child: const Text(
                  '确认',
                  style: TextStyle(fontSize: 18, color: Colors.white), // ✅ 字体加大
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 日选择器
  Widget _buildDayPicker() {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFFFFC107), // ✅ 改选中颜色
        ),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: widget.firstDate ?? DateTime(1900),
        lastDate: widget.lastDate ?? DateTime(2100),
        onDateChanged: (date) => setState(() => _selectedDate = date),
      ),
    );
  }


  /// ✅ 月选择器
  Widget _buildMonthPicker() {
    final months = List.generate(12, (i) => i + 1);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
      ),
      itemCount: months.length,
      itemBuilder: (_, index) {
        final isSelected = _selectedDate.month == months[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, months[index]);
            });
          },
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFFFC107) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${months[index]}月',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// ✅ 年选择器
  Widget _buildYearPicker() {
    final years = List.generate(201, (i) => 1900 + i);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
      ),
      itemCount: years.length,
      itemBuilder: (_, index) {
        final isSelected = _selectedDate.year == years[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(years[index], _selectedDate.month);
            });
          },
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFFFC107) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${years[index]}年',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
