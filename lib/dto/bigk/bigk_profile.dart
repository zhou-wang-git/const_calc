import 'bigk_json.dart';

class BigKProfile {
  final int id;
  final String walletId;
  final String handle;
  final String displayName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String displayCurrency;
  final String state;
  final String bio;
  final bool isPublic;

  const BigKProfile({
    this.id = 0,
    this.walletId = '',
    this.handle = '',
    this.displayName = '',
    this.email = '',
    this.phone = '',
    this.avatarUrl = '',
    this.displayCurrency = '',
    this.state = '',
    this.bio = '',
    this.isPublic = true,
  });

  factory BigKProfile.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json, preferredKey: 'profile');
    return BigKProfile(
      id: bigkInt(data, const ['id']),
      walletId: bigkString(
        data,
        const ['wallet_id', 'external_id', 'id'],
      ),
      handle: bigkString(data, const ['handle', 'preferred_username']),
      displayName: bigkString(data, const ['display_name', 'name']),
      email: bigkString(data, const ['email']),
      phone: bigkString(data, const ['phone', 'mobile']),
      avatarUrl: bigkString(data, const ['avatar_url', 'avatar']),
      displayCurrency: bigkString(
        data,
        const ['display_currency', 'currency', 'currency_code'],
      ),
      state: bigkString(data, const ['state', 'status']),
      bio: bigkString(data, const ['bio', 'about']),
      isPublic: bigkBool(
        data,
        const ['is_public', 'public'],
        fallback: bigkString(data, const ['profile_visibility']) != 'private',
      ),
    );
  }
}

class BigKNotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool marketingEnabled;
  final bool rewardsEnabled;

  const BigKNotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.marketingEnabled = true,
    this.rewardsEnabled = true,
  });

  factory BigKNotificationSettings.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json, preferredKey: 'settings');
    return BigKNotificationSettings(
      pushEnabled: bigkBool(
        data,
        const ['push_enabled', 'push', 'push_notifications'],
        fallback: true,
      ),
      emailEnabled: bigkBool(
        data,
        const ['email_enabled', 'email', 'email_notifications'],
        fallback: true,
      ),
      marketingEnabled: bigkBool(
        data,
        const ['marketing_enabled', 'marketing'],
        fallback: true,
      ),
      rewardsEnabled: bigkBool(
        data,
        const ['rewards_enabled', 'rewards'],
        fallback: true,
      ),
    );
  }
}

class BigKPrivacySettings {
  final bool isPublic;
  final bool showEmail;
  final bool showPhone;
  final bool allowFollowers;

  const BigKPrivacySettings({
    this.isPublic = true,
    this.showEmail = false,
    this.showPhone = false,
    this.allowFollowers = true,
  });

  factory BigKPrivacySettings.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json, preferredKey: 'privacy');
    return BigKPrivacySettings(
      isPublic: bigkBool(
        data,
        const ['is_public', 'public'],
        fallback: bigkString(data, const ['profile_visibility']) != 'private',
      ),
      showEmail: bigkBool(data, const ['show_email', 'email_visible']),
      showPhone: bigkBool(data, const ['show_phone', 'phone_visible']),
      allowFollowers: bigkBool(
        data,
        const ['allow_followers', 'followers_enabled'],
        fallback: true,
      ),
    );
  }
}

class BigKTransferLimits {
  final double dailyLimit;
  final double dailyRemaining;
  final double weeklyLimit;
  final double weeklyRemaining;
  final String currency;

  const BigKTransferLimits({
    this.dailyLimit = 0,
    this.dailyRemaining = 0,
    this.weeklyLimit = 0,
    this.weeklyRemaining = 0,
    this.currency = 'KCC',
  });

  factory BigKTransferLimits.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json, preferredKey: 'limits');
    return BigKTransferLimits(
      dailyLimit: bigkDouble(
        data,
        const ['daily_limit', 'daily_transfer_limit'],
      ),
      dailyRemaining: bigkDouble(
        data,
        const ['daily_remaining', 'daily_transfer_remaining'],
      ),
      weeklyLimit: bigkDouble(
        data,
        const ['weekly_limit', 'weekly_transfer_limit'],
      ),
      weeklyRemaining: bigkDouble(
        data,
        const ['weekly_remaining', 'weekly_transfer_remaining'],
      ),
      currency: bigkString(data, const ['currency', 'display_currency'],
          fallback: 'KCC'),
    );
  }
}

class BigKSessionInfo {
  final String id;
  final String deviceName;
  final String userAgent;
  final String ipAddress;
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  const BigKSessionInfo({
    this.id = '',
    this.deviceName = '',
    this.userAgent = '',
    this.ipAddress = '',
    this.isCurrent = false,
    this.createdAt,
    this.lastActiveAt,
  });

  factory BigKSessionInfo.fromJson(dynamic json) {
    final data = bigkAsMap(json);
    return BigKSessionInfo(
      id: bigkString(data, const ['id', 'session_id']),
      deviceName: bigkString(
        data,
        const ['device_name', 'device', 'device_label'],
      ),
      userAgent: bigkString(data, const ['user_agent', 'agent']),
      ipAddress: bigkString(data, const ['ip_address', 'ip']),
      isCurrent: bigkBool(data, const ['is_current', 'current']),
      createdAt: bigkDateTime(data, const ['created_at']),
      lastActiveAt: bigkDateTime(
        data,
        const ['last_active_at', 'updated_at', 'last_seen_at'],
      ),
    );
  }
}

class BigKWalletLink {
  final bool linked;
  final String walletId;
  final String handle;
  final String email;
  final String state;

  const BigKWalletLink({
    this.linked = false,
    this.walletId = '',
    this.handle = '',
    this.email = '',
    this.state = '',
  });

  factory BigKWalletLink.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json, preferredKey: 'wallet');
    return BigKWalletLink(
      linked: bigkBool(
        data,
        const ['linked', 'is_linked'],
        fallback: bigkString(
          data,
          const ['wallet_id', 'external_id', 'id'],
        ).isNotEmpty,
      ),
      walletId: bigkString(
        data,
        const ['wallet_id', 'external_id', 'id'],
      ),
      handle: bigkString(data, const ['handle', 'preferred_username']),
      email: bigkString(data, const ['email']),
      state: bigkString(data, const ['state', 'status']),
    );
  }
}
