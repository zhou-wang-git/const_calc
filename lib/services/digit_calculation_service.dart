import 'package:const_calc/services/user_service.dart';

import '../dto/digit_calculation.dart';
import '../dto/digit_calculation_info.dart';
import '../dto/digit_calculation_sum.dart';
import '../dto/name_profile_config.dart';
import '../dto/user.dart';
import '../models/qimen_result.dart';
import 'http_service.dart';

class DigitCalculationService {
  /// 数字测算
  static Future<DigitCalculation> getResultList({
    required String name,
    required String ename,
    required String sex,
    required String type,
    required String year,
    required String month,
    required String day,
    required String curyear,
    required String curmonth,
    required String curday,
    required String birthTime,
    required String isBirth,
    int twinStatus = 0,
    String? parentYear,
    String? parentMonth,
    String? parentDay,
  }) async {
    final User? user = await UserService().getUserInfo();
    final Map<String, dynamic> params = {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'name': name,
      'ename': ename,
      'sex': sex,
      'type': type,
      'year': year,
      'month': month,
      'day': day,
      'curyear': curyear,
      'curmonth': curmonth,
      'curday': curday,
      'birth_time': birthTime,
      'is_birth': isBirth,
      'twin_status': twinStatus.toString(),
    };

    // 如果是双胞胎，添加父母生日
    if (twinStatus != 0 && parentYear != null && parentMonth != null && parentDay != null) {
      params['parent_year'] = parentYear;
      params['parent_month'] = parentMonth;
      params['parent_day'] = parentDay;
    }

    final res = await HttpService.post<DigitCalculation>(
      '/apis/getResultList',
      params,
      fromData: (json) => DigitCalculation.fromJson(json)
    );
    return res.data!;
  }

  /// 姓名测算
  static Future<DigitCalculation> getNameResultList({
    required String year,
    required String month,
    required String day,
    required String surname,
    required String lastName,
    required String sex,
    required String hm,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<DigitCalculation>(
      '/apis/getNameResultList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'year': year,
        'month': month,
        'day': day,
        'surname': surname,
        'lastName': lastName,
        'sex': sex,
        'hm': hm,
      },
      fromData: (json) => DigitCalculation.fromJson(json),
    );
    return res.data!;
  }

  /// 测算记录
  static Future<List<DigitCalculationInfo>> getRecordList({
    required String recordsType,
    required String pageNo,
    required String pageSize,
    required String sex,
    required String birthStart,
    required String birthEnd,
    required String csStart,
    required String csEnd,
    required String sx,
    required String star,
    required String main,
    required String keywords,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<DigitCalculationInfo>>(
      '/apis/getRecordList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'records_type': recordsType,
        'pageNo': pageNo,
        'pageSize': pageSize,
        'sex': sex,
        'sx': sx,
        'star': star,
        'main': main,
        'birthStart': birthStart,
        'birthEnd': birthEnd,
        'csStart': csStart,
        'csEnd': csEnd,
        'keywords': keywords,
      },
      fromData: (json) {
        if (json is List) {
          return json
              .map((item) => DigitCalculationInfo.fromJson(item))
              .toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 获取测算详情
  static Future<DigitCalculationInfo> getDetail({required int id}) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<DigitCalculationInfo>(
      '/apis/getDetail',
      {
        'id': id,
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      },
      fromData: (json) => DigitCalculationInfo.fromJson(json),
    );
    return res.data!;
  }

  /// 修改标签信息
  static Future<void> updateTags({
    required String curid,
    required String tags,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.post<void>('/apis/updateTags', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'curid': curid,
      'tags': tags,
    });
  }

  /// 查看权限
  static Future<void> checkAndConsumeApi({required int purviewId}) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.post<void>('/apis/checkAndConsumeApi', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'purviewId': purviewId,
    });
  }

  /// 修改测算记录
  static Future<void> updateUserInfo({
    required String id,
    required String name,
    required String ename,
    required String year,
    required String month,
    required String day,
    required String birthTime,
    required String surname,
    required String lastName,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.post<void>('/apis/updateUserInfo', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'id': id,
      'name': name,
      'ename': ename,
      'year': year,
      'month': month,
      'day': day,
      'birthTime': birthTime,
      'surname': surname,
      'lastName': lastName,
    });
  }

  /// 删除测算记录
  static Future<void> delRecord({required String id}) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.post<void>('/apis/delRecord', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'id': id,
    });
  }

  /// 查询数字测算剩余次数
  static Future<DigitCalculationSum> getResultListSum() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<DigitCalculationSum>(
      '/apis/getResultListSum',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (json) => DigitCalculationSum.fromJson(json),
    );
    return res.data!;
  }

  /// 查询姓名演算配置
  static Future<NameProfileConfig> getNameProfileConfig() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<NameProfileConfig>(
      '/apis/getNameProfileConfig',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (json) => NameProfileConfig.fromJson(json),
    );
    return res.data!;
  }

  /// 检查数字测算配额
  static Future<QuotaInfo> checkQuota() async {
    final User? user = await UserService().getUserInfo();

    if (user == null) {
      return QuotaInfo(remaining: 0, limit: 0, isVip: false);
    }

    try {
      final res = await HttpService.post<Map<String, dynamic>>(
        '/apis/checkAndConsumeApi',
        {
          'token': user.token,
          'userid': user.id.toString(),
          'purviewId': 7,
        },
        fromData: (json) => json as Map<String, dynamic>,
      );

      print('DigitCalculation checkQuota response: ${res.data}');

      if (res.data != null) {
        final quotaInfo = QuotaInfo(
          remaining: res.data!['remaining'] ?? 0,
          limit: res.data!['limit'] ?? 0,
          isVip: (res.data!['limit'] == 999), // 999表示无限
        );
        print('DigitCalculation QuotaInfo: remaining=${quotaInfo.remaining}, limit=${quotaInfo.limit}');
        return quotaInfo;
      }
    } catch (e) {
      // 配额查询失败
      print('DigitCalculation checkQuota error: $e');
    }

    return QuotaInfo(remaining: 0, limit: 0, isVip: false);
  }

  /// 检查姓名测算配额
  static Future<QuotaInfo> checkNameQuota() async {
    final User? user = await UserService().getUserInfo();

    if (user == null) {
      return QuotaInfo(remaining: 0, limit: 0, isVip: false);
    }

    try {
      final res = await HttpService.post<Map<String, dynamic>>(
        '/apis/checkAndConsumeApi',
        {
          'token': user.token,
          'userid': user.id.toString(),
          'purviewId': 8, // 姓名测算的权限ID
        },
        fromData: (json) => json as Map<String, dynamic>,
      );

      print('NameCalculation checkQuota response: ${res.data}');

      if (res.data != null) {
        final quotaInfo = QuotaInfo(
          remaining: res.data!['remaining'] ?? 0,
          limit: res.data!['limit'] ?? 0,
          isVip: (res.data!['limit'] == 999), // 999表示无限
        );
        print('NameCalculation QuotaInfo: remaining=${quotaInfo.remaining}, limit=${quotaInfo.limit}');
        return quotaInfo;
      }
    } catch (e) {
      // 配额查询失败
      print('NameCalculation checkQuota error: $e');
    }

    return QuotaInfo(remaining: 0, limit: 0, isVip: false);
  }
}
