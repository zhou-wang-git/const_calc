import '../dto/user.dart';
import '../models/qimen_result.dart';
import 'http_service.dart';
import 'user_service.dart';

class QimenService {
  /// 获取吉时出行预测
  static Future<QimenResult> getAuspiciousTime({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<QimenResult>(
      '/apis/getAuspiciousTime',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'year': year.toString(),
        'month': month.toString(),
        'day': day.toString(),
        'hour': hour.toString(),
        'minute': minute.toString(),
      },
      fromData: (json) => QimenResult.fromJson(json),
    );
    return res.data!;
  }

  /// 检查查询配额
  static Future<QuotaInfo> checkQuota() async {
    final User? user = await UserService().getUserInfo();

    if (user == null) {
      return QuotaInfo(remaining: 0, limit: 0, isVip: false);
    }

    // 调用后端获取配额信息 (使用ID: 15=吉时出行)
    try {
      final res = await HttpService.post<Map<String, dynamic>>(
        '/apis/checkAndConsumeApi',
        {
          'token': user.token,
          'userid': user.id.toString(),
          'purviewId': 15,
        },
        fromData: (json) => json as Map<String, dynamic>,
      );

      // 从返回数据中读取配额信息
      final int limit = res.data?['limit'] ?? 0;
      final int used = res.data?['used'] ?? 0;
      final int remaining = res.data?['remaining'] ?? 0;

      // 999 次视为无限（VIP）
      final bool isVip = limit >= 999;

      return QuotaInfo(
        remaining: remaining,
        limit: limit,
        isVip: isVip,
      );
    } catch (e) {
      // 如果检查失败，说明没有配额
      return QuotaInfo(
        remaining: 0,
        limit: 0,
        isVip: false,
      );
    }
  }


  /// 获取六壬描述
  static Future<LiurenResult> getLiurenDescription({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    final User? user = await UserService().getUserInfo();
    final res = await HttpService.post<Map<String, dynamic>>(
      '/apis/getLiurenDescription',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'year': year.toString(),
        'month': month.toString(),
        'day': day.toString(),
        'hour': hour.toString(),
        'minute': minute.toString(),
      },
      fromData: (json) => json as Map<String, dynamic>,
    );
    return LiurenResult.fromJson(res.data ?? {});
  }

  /// 获取最近的查询记录
  static Future<QimenLatestRecord?> getLatestRecord() async {
    final User? user = await UserService().getUserInfo();
    if (user == null) return null;

    try {
      final res = await HttpService.post<Map<String, dynamic>>(
        '/apis/getLatestQimenRecord',
        {
          'token': user.token,
          'userid': user.id.toString(),
        },
        fromData: (json) => json as Map<String, dynamic>,
      );

      if (res.data == null) return null;
      return QimenLatestRecord.fromJson(res.data!);
    } catch (e) {
      // 没有记录或查询失败返回null
      return null;
    }
  }
}

/// 最近的查询记录
class QimenLatestRecord {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final QimenResult? qimenResult;
  final LiurenResult? liurenResult;

  QimenLatestRecord({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    this.qimenResult,
    this.liurenResult,
  });

  factory QimenLatestRecord.fromJson(Map<String, dynamic> json) {
    return QimenLatestRecord(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      day: json['day'] ?? 0,
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      qimenResult: json['qimen_result'] != null
          ? QimenResult.fromJson(json['qimen_result'])
          : null,
      liurenResult: json['liuren_result'] != null
          ? LiurenResult.fromJson(json['liuren_result'])
          : null,
    );
  }
}
