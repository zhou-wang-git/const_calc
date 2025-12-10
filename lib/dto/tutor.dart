class Tutor {
  final int id;
  final String email;
  final String mobile;
  final String avatar;
  final int status;
  final String chineseName;
  final String englishName;
  final String levelName;
  final int experienceYears;
  final String location;
  final String background;
  final int sex;
  final int recommendStatus;
  final String hourlyConsultationFee;
  final int addTime;
  final String wx;
  final String wa;
  final String line;
  final String tagIds;
  final String tagNames;
  final int level;
  final int gradeId;
  final int contactNum;

  Tutor({
    required this.id,
    required this.email,
    required this.mobile,
    required this.avatar,
    required this.status,
    required this.chineseName,
    required this.englishName,
    required this.levelName,
    required this.experienceYears,
    required this.location,
    required this.background,
    required this.sex,
    required this.recommendStatus,
    required this.hourlyConsultationFee,
    required this.addTime,
    required this.wx,
    required this.wa,
    required this.line,
    required this.tagIds,
    required this.tagNames,
    required this.level,
    required this.gradeId,
    required this.contactNum,
  });

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? 0,
      chineseName: json['chinese_name'] ?? '',
      englishName: json['english_name'] ?? '',
      levelName: json['level_name'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      location: json['location'] ?? '',
      background: json['background'] ?? '',
      sex: json['sex'] ?? 0,
      recommendStatus: json['recommend_status'] ?? 0,
      hourlyConsultationFee: json['hourly_consultation_fee']?.toString() ?? '0.00',
      addTime: json['add_time'] ?? 0,
      wx: json['wx'] ?? '',
      wa: json['wa'] ?? '',
      line: json['line'] ?? '',
      tagIds: json['tag_ids'] ?? '',
      tagNames: json['tag_names'] ?? '',
      level: json['level'] ?? 0,
      gradeId: json['grade_id'] ?? 0,
      contactNum: json['contact_num'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'mobile': mobile,
      'avatar': avatar,
      'status': status,
      'chinese_name': chineseName,
      'english_name': englishName,
      'level_name': levelName,
      'experience_years': experienceYears,
      'location': location,
      'background': background,
      'sex': sex,
      'recommend_status': recommendStatus,
      'hourly_consultation_fee': hourlyConsultationFee,
      'add_time': addTime,
      'wx': wx,
      'wa': wa,
      'line': line,
      'tag_ids': tagIds,
      'tag_names': tagNames,
      'level': level,
      'grade_id': gradeId,
      'contact_num': contactNum,
    };
  }
}
