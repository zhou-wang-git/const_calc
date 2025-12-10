import '../pages/home/digit_calculation_record_item.dart';

class DigitCalculationInfo {
  final int? id;
  final int? userId;
  final String? name;
  final String? surname;
  final String? lastName;
  final String? eName;
  final int? sex;
  final String? year;
  final String? month;
  final String? day;
  final int? type;
  final int? time;
  final String? birthTime;
  final String? result;
  final String? curYear;
  final String? curMonth;
  final String? curDay;
  final String? result0;
  final String? result1;
  final String? result2;
  final String? result3;
  final String? result4;
  final String? result5;
  final String? result6;
  final String? result7;
  final List<dynamic>? tags;
  final String? mainXg;
  final String? mainWxx;
  final String? userSx;
  final String? userStar;
  final int? century;
  final int? decade;
  final int? recordsType;
  final String? hm;
  final int? status;
  final String? cTime;
  final String? tagStr;

  DigitCalculationInfo({
    this.id,
    this.userId,
    this.name,
    this.surname,
    this.lastName,
    this.eName,
    this.sex,
    this.year,
    this.month,
    this.day,
    this.type,
    this.time,
    this.birthTime,
    this.result,
    this.curYear,
    this.curMonth,
    this.curDay,
    this.result0,
    this.result1,
    this.result2,
    this.result3,
    this.result4,
    this.result5,
    this.result6,
    this.result7,
    this.tags,
    this.mainXg,
    this.mainWxx,
    this.userSx,
    this.userStar,
    this.century,
    this.decade,
    this.recordsType,
    this.hm,
    this.status,
    this.cTime,
    this.tagStr,
  });

  /// ✅ fromJson 方法
  factory DigitCalculationInfo.fromJson(Map<String, dynamic> json) {
    return DigitCalculationInfo(
      id: json['id'] as int?,
      userId: json['userid'] as int?,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      lastName: json['lastName'] as String?,
      eName: json['ename'] as String?,
      sex: json['sex'] as int?,
      year: json['year'] as String?,
      month: json['month'] as String?,
      day: json['day'] as String?,
      type: json['type'] as int?,
      time: json['time'] as int?,
      birthTime: json['birth_time'] as String?,
      result: json['result'] as String?,
      curYear: json['curyear'] as String?,
      curMonth: json['curmonth'] as String?,
      curDay: json['curday'] as String?,
      result0: json['result0'] as String?,
      result1: json['result1'] as String?,
      result2: json['result2'] as String?,
      result3: json['result3'] as String?,
      result4: json['result4'] as String?,
      result5: json['result5'] as String?,
      result6: json['result6'] as String?,
      result7: json['result7'] as String?,
      tags: json['tags'] != null ? List<dynamic>.from(json['tags']) : [],
      mainXg: json['mainxg'] as String?,
      mainWxx: json['mainwxx'] as String?,
      userSx: json['usersx'] as String?,
      userStar: json['userstar'] as String?,
      century: json['century'] as int?,
      decade: json['decade'] as int?,
      recordsType: json['records_type'] as int?,
      hm: json['hm'] as String?,
      status: json['status'] as int?,
      cTime: json['ctime'] as String?,
      tagStr: json['tagstr'] as String?,
    );
  }

  /// ✅ toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userid': userId,
      'name': name,
      'ename': eName,
      'surname': surname,
      'lastName': lastName,
      'sex': sex,
      'year': year,
      'month': month,
      'day': day,
      'type': type,
      'time': time,
      'birth_time': birthTime,
      'result': result,
      'curyear': curYear,
      'curmonth': curMonth,
      'curday': curDay,
      'result0': result0,
      'result1': result1,
      'result2': result2,
      'result3': result3,
      'result4': result4,
      'result5': result5,
      'result6': result6,
      'result7': result7,
      'tags': tags,
      'mainxg': mainXg,
      'mainwxx': mainWxx,
      'usersx': userSx,
      'userstar': userStar,
      'century': century,
      'decade': decade,
      'records_type': recordsType,
      'hm': hm,
      'status': status,
      'ctime': cTime,
      'tagstr': tagStr,
    };
  }

  /// ✅ 安全访问工具（防止 null 报错）
  String get safeName => name ?? '';
  String get safeEName => eName ?? '';
  String get safeYear => year ?? '';
  String get safeMonth => month ?? '';
  String get safeDay => day ?? '';
  String get safeBirthTime => birthTime ?? '未知';
  String get safeUserStar => userStar ?? '';
  String get safeUserSx => userSx ?? '';
}

extension DigitCalculationRecordMapper on DigitCalculationInfo {
  DigitCalculationRecordItem toItem() {
    return DigitCalculationRecordItem(
      id: id ?? 0,
      name: name ?? '',
      gender: sex == 1 ? '女' : sex == 2 ? '男' : '',
      enName: eName ?? '',
      birth: _formatBirth(year, month, day),
      birthTime: birthTime ?? '',
      time: cTime ?? '',
      tagName: tagStr ?? '',
      surname: surname ?? '',
      lastName: lastName ?? '',
    );
  }

  String _formatBirth(String? y, String? m, String? d) {
    if (y == null || m == null || d == null) return '未知';
    return '$y-$m-$d';
  }
}
