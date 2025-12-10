import 'package:const_calc/dto/abs.dart';
import 'package:const_calc/services/user_service.dart';

import '../dto/user.dart';
import 'http_service.dart';

class AbsService {
  /// 获取广告
  static Future<List<Abs>> getAbsList({required String position}) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<Abs>>(
      '/apis/absList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'position': position,
      },
      fromData: (json) {
        if (json is List) {
          return json.map((item) => Abs.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }
}
