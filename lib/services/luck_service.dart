import 'package:const_calc/services/user_service.dart';

import '../dto/luck_detail.dart';
import '../dto/luck_detail_result.dart';
import '../dto/my_fortune.dart';
import '../dto/user.dart';
import 'http_service.dart';

class LuckService {
  /// 获取我的运势
  static Future<MyFortune> getMyFortune() async {
    final User? user = await UserService().getUserInfo();
    String isBirth = '';
    if (user != null && user.birthTime != null) {
      isBirth = user.birthTime!.contains('子时') ? '1' : '0';
    }
    final res = await HttpService.post<MyFortune>(
      '/apis/getMyFortune',
      {
        'is_birth': isBirth,
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      },
      fromData: (json) => MyFortune.fromJson(json),
    );
    return res.data!;
  }

  /// 获取测算详情
  static Future<LuckDetail> getDetail({
    required int id,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<LuckDetail>(
      '/apis/getDetail',
      {
        'id': id,
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      },
      fromData: (json) => LuckDetail.fromJson(json),
    );
    return res.data!;
  }

  /// 获取测算详情
  static Future<LuckDetailResult?> getRes({
    required String year,
    required String month,
    required String day,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<LuckDetailResult?>(
      '/apis/getRes',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'year': year,
        'month': month,
        'day': day,
      },
      fromData: (json) => LuckDetailResult.fromJson(json),
    );
    return res.data!;
  }



}
