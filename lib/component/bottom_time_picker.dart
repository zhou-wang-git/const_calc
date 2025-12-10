import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ✅ 小时-分钟选择器（带“时”“分”）
class BottomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Color confirmColor;
  final Color cancelColor;
  final double pickerFontSize;
  final void Function(String formattedTime, TimeOfDay rawTime) onConfirm;

  const BottomTimePicker({
    super.key,
    required this.initialTime,
    this.confirmColor = Colors.blue,
    this.cancelColor = Colors.grey,
    this.pickerFontSize = 16,
    required this.onConfirm,
  });

  @override
  State<BottomTimePicker> createState() => _BottomTimePickerState();

  /// ✅ 显示底部弹窗
  static Future<void> showTimePicker({
    required BuildContext context,
    required void Function(String formattedTime, TimeOfDay rawTime) onConfirm,
    TimeOfDay? initialTime,
    Color confirmColor = Colors.blue,
    Color cancelColor = Colors.grey,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return BottomTimePicker(
          initialTime: initialTime ?? TimeOfDay.now(),
          confirmColor: confirmColor,
          cancelColor: cancelColor,
          onConfirm: onConfirm,
        );
      },
    );
  }
}

class _BottomTimePickerState extends State<BottomTimePicker> {
  late int selectedHour;
  late int selectedMinute;

  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;

    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? Colors.white24 : const Color(0xFFE5E5E5);

    final hours = List.generate(24, (i) => i); // 0-23
    final minutes = List.generate(60, (i) => i); // 0-59

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // 顶部操作栏
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('取消', style: TextStyle(color: isDark ? Colors.white60 : widget.cancelColor, fontSize: 14)),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final formatted =
                        '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                    widget.onConfirm(formatted, TimeOfDay(hour: selectedHour, minute: selectedMinute));
                  },
                  child: Text('确认',
                      style: TextStyle(color: isDark ? const Color(0xFFFFD54F) : widget.confirmColor, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // ✅ 两列：小时 & 分钟
          Expanded(
            child: Row(
              children: [
                // 小时
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: bgColor,
                    scrollController: hourController,
                    itemExtent: 40,
                    selectionOverlay: null,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedHour = hours[index]);
                    },
                    children: hours
                        .map((h) => Center(
                      child: Text(
                        '${h.toString().padLeft(2, '0')} 时',
                        style: TextStyle(fontSize: widget.pickerFontSize, color: textColor),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                // 分钟
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: bgColor,
                    scrollController: minuteController,
                    itemExtent: 40,
                    selectionOverlay: null,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedMinute = minutes[index]);
                    },
                    children: minutes
                        .map((m) => Center(
                      child: Text(
                        '${m.toString().padLeft(2, '0')} 分',
                        style: TextStyle(fontSize: widget.pickerFontSize, color: textColor),
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
