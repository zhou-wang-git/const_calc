import 'package:const_calc/dto/tag.dart';
import 'package:const_calc/services/user_service.dart';

import '../dto/Tutor.dart';
import '../dto/user.dart';
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
}
