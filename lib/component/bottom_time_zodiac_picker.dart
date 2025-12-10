import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 十二时辰日期选择器
class BottomTimeZodiacPicker extends StatefulWidget {
  final String initialValue;
  final void Function(String selected) onConfirm;

  const BottomTimeZodiacPicker({
    super.key,
    required this.initialValue,
    required this.onConfirm,
  });

  @override
  State<BottomTimeZodiacPicker> createState() => _BottomTimeZodiacPickerState();

  static Future<void> showTimeZodiacPicker(BuildContext context,
      {required String initialValue,
        required void Function(String selected) onConfirm}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => BottomTimeZodiacPicker(
        initialValue: initialValue,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _BottomTimeZodiacPickerState extends State<BottomTimeZodiacPicker> {
  final List<String> options = [
    "未知",
    "23-01 子时",
    "01-03 丑时",
    "03-05 寅时",
    "05-07 卯时",
    "07-09 辰时",
    "09-11 巳时",
    "11-13 午时",
    "13-15 未时",
    "15-17 申时",
    "17-19 酉时",
    "19-21 戌时",
    "21-23 亥时"
  ];

  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = options.indexOf(widget.initialValue);
    if (selectedIndex == -1) selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? Colors.white24 : const Color(0xFFE5E5E5);

    return SizedBox(
      height: 260,
      child: Column(
        children: [
          // 顶部按钮
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text("取消", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onConfirm(options[selectedIndex]);
                  },
                  child: Text("确认",
                      style: TextStyle(
                          color: isDark ? const Color(0xFFFFD54F) : theme.primaryColor)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // 单列选择器
          Expanded(
            child: CupertinoPicker(
              backgroundColor: bgColor,
              scrollController:
              FixedExtentScrollController(initialItem: selectedIndex),
              itemExtent: 44,
              onSelectedItemChanged: (index) {
                selectedIndex = index;
              },
              selectionOverlay: Container(), // 去掉默认选中背景
              children: options
                  .map((e) => Center(
                  child: Text(
                    e,
                    style: TextStyle(fontSize: 16, color: textColor),
                  )))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
