import 'tutor_apply_material.dart';

/// 导师申请数据模型
class TutorApply {
  final int id;
  final int userId;
  final String chineseName;
  final String englishName;
  final int gradeId;
  final String country;
  final String location;
  final String email;
  final String mobile;
  final String background;
  final int status; // 0待审核 1已通过 2已拒绝
  final String rejectReason;
  final int addTime;
  final int updateTime;
  final int reviewTime;
  final int reviewerId;
  final List<TutorApplyMaterial> materials;

  TutorApply({
    required this.id,
    required this.userId,
    required this.chineseName,
    required this.englishName,
    required this.gradeId,
    required this.country,
    required this.location,
    required this.email,
    required this.mobile,
    required this.background,
    required this.status,
    required this.rejectReason,
    required this.addTime,
    required this.updateTime,
    required this.reviewTime,
    required this.reviewerId,
    required this.materials,
  });

  factory TutorApply.fromJson(Map<String, dynamic> json) {
    return TutorApply(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      chineseName: json['chinese_name'] ?? '',
      englishName: json['english_name'] ?? '',
      gradeId: json['grade_id'] ?? 1,
      country: json['country'] ?? '',
      location: json['location'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      background: json['background'] ?? '',
      status: json['status'] ?? 0,
      rejectReason: json['reject_reason'] ?? '',
      addTime: json['add_time'] ?? 0,
      updateTime: json['update_time'] ?? 0,
      reviewTime: json['review_time'] ?? 0,
      reviewerId: json['reviewer_id'] ?? 0,
      materials: json['materials'] is List
          ? (json['materials'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TutorApplyMaterial.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'chinese_name': chineseName,
      'english_name': englishName,
      'grade_id': gradeId,
      'country': country,
      'location': location,
      'email': email,
      'mobile': mobile,
      'background': background,
      'status': status,
      'reject_reason': rejectReason,
      'add_time': addTime,
      'update_time': updateTime,
      'review_time': reviewTime,
      'reviewer_id': reviewerId,
      'materials': materials
          .map((item) => {
                'id': item.id,
                'apply_id': item.applyId,
                'user_id': item.userId,
                'material_type': item.materialType,
                'material_name': item.materialName,
                'attachment_id': item.attachmentId,
                'file_url': item.fileUrl,
                'file_name': item.fileName,
                'file_ext': item.fileExt,
                'mime_type': item.mimeType,
                'file_size': item.fileSize,
                'status': item.status,
                'review_remark': item.reviewRemark,
                'add_time': item.addTime,
                'update_time': item.updateTime,
              })
          .toList(),
    };
  }

  /// 获取状态文本
  String get statusText {
    switch (status) {
      case 0:
        return '待审核';
      case 1:
        return '已通过';
      case 2:
        return '已拒绝';
      default:
        return '未知';
    }
  }

  /// 获取等级文本
  String get gradeName {
    switch (gradeId) {
      case 1:
        return '启蒙导师';
      case 2:
        return '大宗导师';
      case 3:
        return '传承导师';
      default:
        return '未知';
    }
  }
}
