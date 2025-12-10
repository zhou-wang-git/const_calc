class LuckDetail {
  final int id;
  final int userid;
  final String name;
  final String ename;
  final int sex;
  final String year;
  final String month;
  final String day;
  final int type;
  final int time;
  final String birthTime;
  final String? result; // 原始 JSON 字符串
  final String? result0;
  final String? result1;
  final String? result2;
  final String? result3;
  final String? desc;
  final String? mainDesc;
  final String? desc0;
  final String? mainDesc0;
  final String? desc1;
  final String? mainDesc1;
  final String? desc2;
  final String? mainDesc2;
  final String? userStar;
  final String? userSx;
  final int twinStatus; // 0=不是双胞胎, 1=长, 2=幼
  final String? parentYear;
  final String? parentMonth;
  final String? parentDay;

  LuckDetail({
    required this.id,
    required this.userid,
    required this.name,
    required this.ename,
    required this.sex,
    required this.year,
    required this.month,
    required this.day,
    required this.type,
    required this.time,
    required this.birthTime,
    this.result,
    this.result0,
    this.result1,
    this.result2,
    this.result3,
    this.desc,
    this.mainDesc,
    this.desc0,
    this.mainDesc0,
    this.desc1,
    this.mainDesc1,
    this.desc2,
    this.mainDesc2,
    this.userStar,
    this.userSx,
    this.twinStatus = 0,
    this.parentYear,
    this.parentMonth,
    this.parentDay,
  });

  factory LuckDetail.fromJson(Map<String, dynamic> json) {
    return LuckDetail(
      id: json['id'] ?? 0,
      userid: json['userid'] ?? 0,
      name: json['name'] ?? '',
      ename: json['ename'] ?? '',
      sex: json['sex'] ?? 0,
      year: json['year'] ?? '',
      month: json['month'] ?? '',
      day: json['day'] ?? '',
      type: json['type'] ?? 0,
      time: json['time'] ?? 0,
      birthTime: json['birth_time'] ?? '',
      result: json['result'],
      result0: json['result0'],
      result1: json['result1'],
      result2: json['result2'],
      result3: json['result3'],
      desc: json['desc'],
      mainDesc: json['main_desc'],
      desc0: json['desc0'],
      mainDesc0: json['main_desc0'],
      desc1: json['desc1'],
      mainDesc1: json['main_desc1'],
      desc2: json['desc2'],
      mainDesc2: json['main_desc2'],
      userStar: json['userstar'],
      userSx: json['usersx'],
      twinStatus: json['twin_status'] ?? 0,
      parentYear: json['parent_year']?.toString(),
      parentMonth: json['parent_month']?.toString(),
      parentDay: json['parent_day']?.toString(),
    );
  }
}
