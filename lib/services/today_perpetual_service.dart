import 'package:const_calc/services/user_service.dart';

import '../dto/today_perpetual.dart';
import '../dto/user.dart';
import '../services/http_service.dart';

class TodayPerpetualService {
  static Future<TodayPerpetual> getToday() async {
    final User? user = await UserService().getUserInfo();

    final res = await HttpService.post<TodayPerpetual>(
      '/apis/getTodayPerpetual',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
      }, // 如果接口无参数
      fromData: (json) => TodayPerpetual.fromJson(json),
    );

    return res.data!;
  }

  static Future<TodayPerpetual?> getPerpetualByDate(String date) async {
    final User? user = await UserService().getUserInfo();

    final res = await HttpService.post<TodayPerpetual>(
      '/apis/getPerpetualByDate',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'date': date, // Format: YYYY-MM-DD
      },
      fromData: (json) => TodayPerpetual.fromJson(json),
    );

    return res.data;
  }
}
