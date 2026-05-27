class TutorApplyMaterial {
  final int id;
  final int applyId;
  final int userId;
  final String materialType;
  final String materialTypeText;
  final String materialName;
  final int attachmentId;
  final String fileUrl;
  final String fileName;
  final String fileExt;
  final String mimeType;
  final int fileSize;
  final String fileSizeText;
  final int status;
  final String reviewRemark;
  final int addTime;
  final int updateTime;
  final bool isImage;

  TutorApplyMaterial({
    required this.id,
    required this.applyId,
    required this.userId,
    required this.materialType,
    required this.materialTypeText,
    required this.materialName,
    required this.attachmentId,
    required this.fileUrl,
    required this.fileName,
    required this.fileExt,
    required this.mimeType,
    required this.fileSize,
    required this.fileSizeText,
    required this.status,
    required this.reviewRemark,
    required this.addTime,
    required this.updateTime,
    required this.isImage,
  });

  factory TutorApplyMaterial.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

    return TutorApplyMaterial(
      id: parseInt(json['id']),
      applyId: parseInt(json['apply_id']),
      userId: parseInt(json['user_id']),
      materialType: json['material_type']?.toString() ?? 'other',
      materialTypeText: json['material_type_text']?.toString() ?? '其他资料',
      materialName: json['material_name']?.toString() ?? '',
      attachmentId: parseInt(json['attachment_id']),
      fileUrl: json['file_url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileExt: json['file_ext']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      fileSize: parseInt(json['file_size']),
      fileSizeText: json['file_size_text']?.toString() ?? '',
      status: parseInt(json['status']),
      reviewRemark: json['review_remark']?.toString() ?? '',
      addTime: parseInt(json['add_time']),
      updateTime: parseInt(json['update_time']),
      isImage: '${json['is_image'] ?? 0}' == '1' || json['is_image'] == true,
    );
  }
}
