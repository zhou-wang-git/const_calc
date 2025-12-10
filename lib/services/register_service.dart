import 'http_service.dart';

class RegisterService {
  /// 发送注册验证邮件
  static Future<void> sendRegisterEmail({
    required String email
  }) async {
    await HttpService.postForm<void>(
      '/apis/sendRegisterEmail',
      {
        'email': email,
        'token': '',
        'userid': '',
      },
    );
  }

  /// 发送找回密码验证邮件
  static Future<void> sendRecoverPasswordEmail({
    required String email
  }) async {
    await HttpService.postForm<void>(
      '/apis/sendRecoverPasswordEmail',
      {
        'email': email,
        'token': '',
        'userid': '',
      },
    );
  }

  /// 重置密码（找回密码）
  static Future<void> recoverPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await HttpService.postForm<void>(
      '/apis/recoverPassword',
      {
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'token': '',
        'userid': '',
      },
    );
  }

  /// 注册
  static Future<void> registerAccount({
    required String realName,
    required String account,
    required String psd,
    required String email,
    required String repsd,
    required String year,
    required String month,
    required String day,
    required String code,
    required String sex,
    required String birthTime,
  }) async {
    await HttpService.postForm<void>(
      '/apis/registerAccount',
      {
        'token': '',
        'userid': '',
        'real_name': realName,
        'account': account,
        'email': email,
        'repsd': repsd,
        'psd': psd,
        'year': year,
        'month': month,
        'day': day,
        'code': code,
        'sex': sex,
        'birthTime': birthTime,
      },
    );
  }
}
