import 'dart:typed_data';
import 'package:const_calc/dto/vip_fee.dart';
import 'package:const_calc/dto/vip_purview.dart';
import 'package:const_calc/services/user_service.dart';

import '../dto/avatar.dart';
import '../dto/magic_link.dart';
import '../dto/order_record.dart';
import '../dto/upload_file.dart';
import '../dto/user.dart';
import 'http_service.dart';

class MyService {
  /// 获取vip权益
  static Future<List<VipPurview>> getVipPurview() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<VipPurview>>(
      '/apis/getVipPurview',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (json) {
        if (json is List) {
          return json.map((item) => VipPurview.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 获取vip费用
  static Future<List<VipFee>> getFeeByVipId({
    required String vipLevelId,
  }) async {
    final res = await HttpService.get<List<VipFee>>(
      '/apis/getFeeByVipId?vipLevelId=$vipLevelId',
      fromData: (json) {
        if (json is List) {
          return json.map((item) => VipFee.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 更新用户信息
  static Future<void> updateMember({
    required String name,
    required String sex,
    required String birthTime,
    required String curid,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/updateMember', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'real_name': name,
      'sex': sex,
      'birth_time': birthTime,
      'curid': curid,
    });
  }

  /// 更新用户生日信息
  static Future<void> updateBirthday({
    required String year,
    required String month,
    required String day,
    required String curid,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/updateBirthday', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'year': year,
      'month': month,
      'day': day,
      'curid': curid,
    });
  }

  /// 获取头像列表
  static Future<List<Avatar>> getAvatar() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<Avatar>>(
      '/apis/getAvatar',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (json) {
        if (json is List) {
          return json.map((item) => Avatar.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 上传文件
  static Future<UploadFile> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postMultipart(
      '/apis/uploadFile',
      fields: {'token': user?.token ?? ''},
      fileBytes: fileBytes,
      fileName: fileName,
      fromData: (json) => UploadFile.fromJson(json),
    );
    return res.data!;
  }

  /// 更新用户头像
  static Future<void> updateAvatar({required String avatar}) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/updateAvatar', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'avatar': avatar,
    });
  }

  /// 修改密码
  static Future<void> updateInfo({
    required String psd,
    required String repsd,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/updateInfo', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'psd': psd,
      'repsd': repsd,
    });
  }

  /// 意见反馈
  static Future<void> addFeedback({
    required String info,
    required String email,
    required String title,
  }) async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/addFeedback', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
      'info': info,
      'email': email,
      'title': title,
    });
  }

  /// 获取消费记录
  static Future<List<OrderRecord>> getOrderList({
    required String pageNo,
    required String pageSize,
    String? keyword,
    String? orderSn,
    String? payEmail,
    String? payName,
    String? payTimeStart,
    String? amountStart,
    String? payTimeEnd,
    String? amountEnd,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<List<OrderRecord>>(
      '/apis/getOrderList',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'pageNo': pageNo,
        'pageSize': pageSize,
        'keyword': keyword ?? '',
        'payEmail': payEmail ?? '',
        'payName': payName ?? '',
        'payTimeStart': payTimeStart ?? '',
        'amountStart': amountStart ?? '',
        'payTimeEnd': payTimeEnd ?? '',
        'amountEnd': amountEnd ?? '',
      },
      fromData: (json) {
        if (json is List) {
          return json.map((item) => OrderRecord.fromJson(item)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  /// 注销用户
  static Future<void> getMemberDelete() async {
    final User? user = await UserService().getUserInfo();
    await HttpService.postForm<void>('/apis/getMemberdelete', {
      'token': user?.token ?? '',
      'userid': user?.id.toString() ?? '',
    });
  }

  /// 生成商城链接
  static Future<MagicLink> generateShopMagicLink() async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.postForm<MagicLink>(
      '/apis/generateShopMagicLink',
      {'token': user?.token ?? '', 'userid': user?.id.toString() ?? ''},
      fromData: (json) => MagicLink.fromJson(json),
    );
    return res.data!;
  }
}
