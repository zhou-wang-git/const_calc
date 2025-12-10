/// 双胞胎虚拟生日计算工具
class TwinUtil {
  /// 计算双胞胎的虚拟生日
  ///
  /// [childBirthday]: 双胞胎的生日 "1973-10-06"
  /// [parentBirthday]: 父母的生日 "1950-08-13"
  ///
  /// 返回虚拟生日格式: "year-month-day" (例如: "26-09-01")
  /// 注意：年份是两位数表示 (世纪+年代合并后的结果)
  static String calculateVirtualBirthday(String childBirthday, String parentBirthday) {
    // 解析日期
    final childParts = childBirthday.split('-');
    final parentParts = parentBirthday.split('-');

    if (childParts.length != 3 || parentParts.length != 3) {
      throw ArgumentError('日期格式错误，应为 yyyy-MM-dd');
    }

    final childYear = childParts[0];
    final childMonth = childParts[1];
    final childDay = childParts[2];

    final parentYear = parentParts[0];
    final parentMonth = parentParts[1];
    final parentDay = parentParts[2];

    // 1. 计算年份（世纪 + 年代）
    // 世纪：父亲世纪简化 + 儿子世纪简化
    final parentCentury = _sumDigits(parentYear.substring(0, 2));
    final childCentury = _sumDigits(childYear.substring(0, 2));
    final virtualCentury = parentCentury + childCentury;

    // 年代：父亲年代简化 + 儿子年代简化
    final parentDecade = _sumDigits(parentYear.substring(2, 4));
    final childDecade = _sumDigits(childYear.substring(2, 4));
    final virtualDecade = parentDecade + childDecade;

    // 合并世纪和年代（不简化），补齐为4位
    final virtualYear = virtualCentury.toString().padLeft(2, '0') +
                        virtualDecade.toString().padLeft(2, '0');

    // 2. 计算月份（相加后需要继续简化）
    final parentMonthSum = _sumDigits(parentMonth);
    final childMonthSum = _sumDigits(childMonth);
    final monthSum = parentMonthSum + childMonthSum;
    // 如果超过9，需要继续简化到个位数
    final virtualMonth = _sumDigitsFromInt(monthSum).toString().padLeft(2, '0');

    // 3. 计算日期（相加后需要继续简化）
    final parentDaySum = _sumDigits(parentDay);
    final childDaySum = _sumDigits(childDay);
    final daySum = parentDaySum + childDaySum;
    // 如果超过9，需要继续简化到个位数
    final virtualDay = _sumDigitsFromInt(daySum).toString().padLeft(2, '0');

    return '$virtualYear-$virtualMonth-$virtualDay';
  }

  /// 将数字的各位相加并简化到个位数
  /// 例如: "19" -> 1+9=10 -> 1+0=1
  static int _sumDigits(String numStr) {
    int sum = 0;
    for (int i = 0; i < numStr.length; i++) {
      sum += int.parse(numStr[i]);
    }

    // 持续简化直到个位数
    while (sum >= 10) {
      int temp = 0;
      while (sum > 0) {
        temp += sum % 10;
        sum ~/= 10;
      }
      sum = temp;
    }

    return sum;
  }

  /// 将整数的各位相加并简化到个位数
  /// 例如: 11 -> 1+1=2, 18 -> 1+8=9
  static int _sumDigitsFromInt(int num) {
    int sum = num;

    // 持续简化直到个位数
    while (sum >= 10) {
      int temp = 0;
      while (sum > 0) {
        temp += sum % 10;
        sum ~/= 10;
      }
      sum = temp;
    }

    return sum;
  }
}
