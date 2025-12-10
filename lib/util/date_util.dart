import 'package:intl/intl.dart';

class DateUtil {
  /// 获取当前年份 (yyyy)
  static String getCurrentYear() {
    final now = DateTime.now();
    return now.year.toString();
  }

  /// 获取当前月份 (MM) ，补0
  static String getCurrentMonth() {
    final now = DateTime.now();
    return now.month.toString().padLeft(2, '0');
  }

  /// 获取当前日期 (dd) ，补0
  static String getCurrentDay() {
    final now = DateTime.now();
    return now.day.toString().padLeft(2, '0');
  }

  /// 根据格式化字符串解析日期
  /// [dateStr] 日期字符串
  /// [pattern] 格式，例如 'yyyy-MM-dd' / 'yyyy年MM月dd日' / 'yyyy/MM/dd HH:mm'
  static DateTime? parseDate(String dateStr, String pattern) {
    try {
      final formatter = DateFormat(pattern);
      return formatter.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}