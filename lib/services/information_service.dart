import 'package:const_calc/services/user_service.dart';

import '../dto/library_character.dart';
import '../dto/library_radical.dart';
import '../dto/radical.dart';
import '../dto/user.dart';
import 'http_service.dart';

class InformationService {
  /// 资料库 主性格说明, 81组数字说明 查询
  static Future<List<LibraryCharacter>> getLibraryCharacterList({
    required String pageNo,
    required String pageSize,
    required String type,
    required String keywords,
    required String brush,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<LibraryCharacter>>(
      '/apis/getLibraryCharacterList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'type': type,
        'keywords': keywords,
        'brush': brush,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
      fromData: (json) {
        if (json is List) {
          return json.map((item) => LibraryCharacter.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 资料库 五行总览 查询
  static Future<List<LibraryCharacter>> getLibraryElementsList({
    required String pageNo,
    required String pageSize,
    required String keywords,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<LibraryCharacter>>(
      '/apis/getLibraryElementsList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'keywords': keywords,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
      fromData: (json) {
        if (json is List) {
          return json.map((item) => LibraryCharacter.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 资料库 边旁说明 查询
  static Future<List<LibraryRadical>> getRadicalList({
    required String pageNo,
    required String pageSize,
    required String keywords,
    required String brush,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<LibraryRadical>>(
      '/apis/getRadicalList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'keywords': keywords,
        'brush': brush,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
      fromData: (json) {
        if (json is List) {
          return json.map((item) => LibraryRadical.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 根据边旁部首获取边旁信息
  static Future<Radical> getRadical({required String title}) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<Radical>('/apis/getRadical', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'title': title,
    }, fromData: (json) => Radical.fromJson(json));

    return res.data!;
  }

  /// 根据81组数字获取说明
  static Future<LibraryCharacter?> getLibraryContent({
    required String title,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<LibraryCharacter>(
      '/apis/getLibraryContent',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'title': title,
      },
      fromData: (json) => LibraryCharacter.fromJson(json),
    );

    return res.data;
  }
}
