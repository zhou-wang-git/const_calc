import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_json.dart';
import '../../dto/bigk/bigk_profile.dart';
import 'bigk_http_service.dart';

class BigKProfileService {
  static Future<BigKProfile> getProfile() async {
    debugPrint('BigKProfileService: Fetching profile...');

    return BigKHttpService.getWallet<BigKProfile>(
      '/profile',
      BigKProfile.fromJson,
    );
  }

  static Future<BigKProfile> updateProfile({
    required String displayName,
    required String handle,
    String bio = '',
    String phone = '',
  }) async {
    debugPrint('BigKProfileService: Updating profile...');

    return BigKHttpService.putWallet<BigKProfile>(
      '/profile',
      <String, dynamic>{
        'display_name': displayName.trim(),
        'handle': handle.trim(),
        if (bio.trim().isNotEmpty) 'bio': bio.trim(),
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      BigKProfile.fromJson,
    );
  }

  static Future<BigKProfile> uploadAvatar({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    debugPrint('BigKProfileService: Uploading avatar...');

    return BigKHttpService.postWalletMultipart<BigKProfile>(
      '/profile/avatar',
      fileBytes: fileBytes,
      fileName: fileName,
      fileField: 'avatar',
      fromData: BigKProfile.fromJson,
    );
  }

  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    debugPrint('BigKProfileService: Registering device token...');

    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/profile/device-token',
      <String, dynamic>{
        'device_token': token.trim(),
        'platform': platform.trim(),
      },
      bigkAsMap,
    );
  }

  static Future<void> updateCurrency(String currencyCode) async {
    debugPrint('BigKProfileService: Updating currency...');

    await BigKHttpService.putWallet<Map<String, dynamic>>(
      '/profile/currency',
      <String, dynamic>{'currency': currencyCode.trim().toUpperCase()},
      bigkAsMap,
    );
  }

  static Future<BigKNotificationSettings> getNotificationSettings() async {
    debugPrint('BigKProfileService: Fetching notification settings...');

    return BigKHttpService.getWallet<BigKNotificationSettings>(
      '/profile/notification-settings',
      BigKNotificationSettings.fromJson,
    );
  }

  static Future<void> updateNotificationSettings(
    BigKNotificationSettings settings,
  ) async {
    debugPrint('BigKProfileService: Updating notification settings...');

    await BigKHttpService.putWallet<Map<String, dynamic>>(
      '/profile/notifications',
      <String, dynamic>{
        'push_enabled': settings.pushEnabled,
        'email_enabled': settings.emailEnabled,
        'marketing_enabled': settings.marketingEnabled,
        'rewards_enabled': settings.rewardsEnabled,
      },
      bigkAsMap,
    );
  }

  static Future<BigKPrivacySettings> getPrivacySettings() async {
    debugPrint('BigKProfileService: Fetching privacy settings via profile...');

    return BigKHttpService.getWallet<BigKPrivacySettings>(
      '/profile',
      BigKPrivacySettings.fromJson,
    );
  }

  static Future<void> updatePrivacySettings(
    BigKPrivacySettings settings,
  ) async {
    debugPrint('BigKProfileService: Updating privacy settings...');

    await BigKHttpService.putWallet<Map<String, dynamic>>(
      '/profile/privacy',
      <String, dynamic>{
        'is_public': settings.isPublic,
        'show_email': settings.showEmail,
        'show_phone': settings.showPhone,
        'allow_followers': settings.allowFollowers,
      },
      bigkAsMap,
    );
  }

  static Future<BigKTransferLimits> getLimits() async {
    debugPrint('BigKProfileService: Fetching transfer limits...');

    return BigKHttpService.getWallet<BigKTransferLimits>(
      '/app/limits',
      BigKTransferLimits.fromJson,
    );
  }
}
