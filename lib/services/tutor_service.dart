import 'dart:convert';
import 'dart:typed_data';

import 'package:const_calc/dto/tag.dart';
import 'package:const_calc/services/user_service.dart';

import '../dto/Tutor.dart';
import '../dto/tutor_apply.dart';
import '../dto/tutor_apply_material.dart';
import '../dto/user.dart';
import '../pages/home/tutor_consult_search_filter_bar.dart';
import 'http_service.dart';

class TutorService {
  static Future<List<Tutor>> getTutorList() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<Tutor>>(
      '/apis/getRutorList',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (data) {
        if (data is List) {
          return data
              .map((e) => Tutor.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    return res.data ?? [];
  }

  static Future<List<Tutor>> getTutorPage({
    required String pageNo,
    required String pageSize,
    required String name,
    required String tagIds,
    required String sex,
    required String location,
    required String country,
    required String levelName,
    required String gradeId,
    required String experienceYears,
    required String hourlyConsultationFee,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<Tutor>>(
      '/apis/getTutorPage',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'pageNo': pageNo,
        'pageSize': pageSize,
        'name': name,
        'tag_ids': tagIds,
        'sex': sex,
        'location': location,
        'country': country,
        'level_name': levelName,
        'grade_id': gradeId,
        'experience_years': experienceYears,
        'hourly_consultation_fee': hourlyConsultationFee,
      },
      fromData: (data) {
        if (data is List) {
          return data
              .map((e) => Tutor.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    return res.data ?? [];
  }

  /// 获取导师标签
  static Future<List<Tag>> getTagList() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<Tag>>(
      '/apis/getTag',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (data) {
        if (data is List) {
          return data
              .map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    return res.data ?? [];
  }

  /// 获取国家列表（从现有导师数据提取）
  static Future<List<LabelValue>> getCountryList() async {
    final res = await HttpService.postForm<List<LabelValue>>(
      '/apis/getCountryList',
      {},
      fromData: (data) {
        if (data is List) {
          return data.map((e) {
            final map = e as Map<String, dynamic>;
            return LabelValue(map['label'] ?? '', map['value'] ?? '');
          }).toList();
        }
        return [];
      },
    );

    return res.data ?? [];
  }

  /// 提交导师申请
  static Future<void> submitTutorApply({
    required String chineseName,
    String? englishName,
    required int gradeId,
    required String country,
    required String location,
    String? email,
    String? mobile,
    String? background,
    List<int>? materialIds,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>(
      '/apis/submitTutorApply',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'chinese_name': chineseName,
        'english_name': englishName ?? '',
        'grade_id': gradeId.toString(),
        'country': country,
        'location': location,
        'email': email ?? '',
        'mobile': mobile ?? '',
        'background': background ?? '',
        'material_ids': jsonEncode(materialIds ?? const []),
      },
      fromData: (_) {},
    );
  }

  static Future<List<TutorApplyMaterial>> getTutorApplyMaterials() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<TutorApplyMaterial>>(
      '/apis/getTutorApplyMaterials',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      },
      fromData: (data) {
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(TutorApplyMaterial.fromJson)
              .toList();
        }
        return [];
      },
    );

    return res.data ?? [];
  }

  static Future<TutorApplyMaterial> uploadTutorApplyMaterial({
    required String materialType,
    required String fileName,
    required Uint8List fileBytes,
    String? materialName,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postMultipart<TutorApplyMaterial>(
      '/apis/uploadTutorApplyMaterial',
      fields: {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'material_type': materialType,
        'material_name': materialName ?? '',
      },
      fileBytes: fileBytes,
      fileName: fileName,
      fromData: (json) => TutorApplyMaterial.fromJson(
        json as Map<String, dynamic>,
      ),
    );

    return res.data!;
  }

  static Future<void> deleteTutorApplyMaterial({required int id}) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>(
      '/apis/deleteTutorApplyMaterial',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'id': id.toString(),
      },
      fromData: (_) {},
    );
  }

  /// 获取导师申请状态
  static Future<TutorApply?> getTutorApplyStatus() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<TutorApply?>(
      '/apis/getTutorApplyStatus',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      },
      fromData: (data) {
        if (data != null && data is Map<String, dynamic>) {
          return TutorApply.fromJson(data);
        }
        return null;
      },
    );
    return res.data;
  }
}
