import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../handler/api_exception.dart';
import 'kcc/kcc_auth_service.dart';

class RegisterService {
  static const String _registerOtpKey = 'kcc_register_otp_session';
  static const String _recoverOtpKey = 'kcc_recover_otp_session';

  static Future<void> sendRegisterEmail({
    required String email,
  }) async {
    final session = await KccAuthService().requestOtp(
      channel: 'email',
      target: email.trim(),
      purpose: 'registration',
    );
    await _saveOtpSession(_registerOtpKey, email.trim(), session.sessionId);
  }

  static Future<void> sendRecoverPasswordEmail({
    required String email,
  }) async {
    final session = await KccAuthService().forgotPassword(
      email: email.trim(),
    );
    await _saveOtpSession(_recoverOtpKey, email.trim(), session.sessionId);
  }

  static Future<void> recoverPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim();
    final sessionId = await _readOtpSession(_recoverOtpKey, normalizedEmail);
    if (sessionId == null || sessionId.isEmpty) {
      throw ApiException(400, 'Please request the reset code first.');
    }

    final verifyResult = await KccAuthService().verifyResetOtp(
      email: normalizedEmail,
      sessionId: sessionId,
      otp: code.trim(),
    );

    await KccAuthService().resetPassword(
      email: normalizedEmail,
      resetToken: verifyResult.resetToken,
      password: newPassword,
      passwordConfirmation: confirmPassword,
    );

    await _clearOtpSession(_recoverOtpKey);
  }

  static Future<void> registerAccount({
    required String realName,
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
    final otpSessionId = await _readOtpSession(_registerOtpKey, email.trim());
    if (otpSessionId == null || otpSessionId.isEmpty) {
      throw ApiException(400, 'Please request the registration OTP first.');
    }

    await KccAuthService().verifyOtp(
      sessionId: otpSessionId,
      code: code.trim(),
    );

    await KccAuthService().register(
      otpSessionId: otpSessionId,
      password: psd,
      passwordConfirmation: repsd,
      displayName: realName.trim(),
    );

    await _clearOtpSession(_registerOtpKey);
  }

  static Future<void> _saveOtpSession(
    String key,
    String email,
    String sessionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'email': email,
        'session_id': sessionId,
      }),
    );
  }

  static Future<String?> _readOtpSession(String key, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final savedEmail = decoded['email']?.toString().trim() ?? '';
    if (savedEmail != email) {
      return null;
    }

    return decoded['session_id']?.toString();
  }

  static Future<void> _clearOtpSession(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
