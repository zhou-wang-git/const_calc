import 'package:flutter/foundation.dart';

import '../dto/user.dart';
import '../handler/api_exception.dart';
import 'auth_service.dart';
import 'bigk/bigk_auth_service.dart';
import 'user_service.dart';

class MallWalletProvisionRequiredException implements Exception {
  final String message;

  const MallWalletProvisionRequiredException([
    this.message = 'Wallet setup is required before continuing.',
  ]);

  @override
  String toString() => message;
}

class ShopSessionService {
  static final ShopSessionService _instance = ShopSessionService._internal();

  factory ShopSessionService() => _instance;

  ShopSessionService._internal();

  Future<void> ensureMallSession({bool createWalletIfMissing = false}) async {
    if (!AuthService().isLoggedIn) {
      throw ApiException(401, 'Please login first.');
    }

    if (!BigKAuthService().isLinked ||
        BigKAuthService().clientId != BigKAuthService.walletClientId) {
      await BigKAuthService().logout();
      throw ApiException(
        401,
        'Mall session has expired. Please login again before entering the mall.',
      );
    }

    final User? user;
    try {
      user = await UserService().refreshUserInfo();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(-1, 'Failed to load current user: $e');
    }

    if (user == null) {
      throw ApiException(401, 'Please login first.');
    }

    final profile = await _requireUnifiedIdentity();
    final kccUserId = profile['sub']?.toString() ?? '';
    if (kccUserId.isEmpty) {
      await BigKAuthService().logout();
      throw ApiException(
        401,
        'Unified identity session has expired. Please login again.',
      );
    }

    if (user.mallBinding.kccUserId.isNotEmpty &&
        user.mallBinding.kccUserId != kccUserId) {
      await BigKAuthService().logout();
      throw ApiException(
        401,
        'Current KCC identity does not match this account. Please login again.',
      );
    }

    final walletId = await _ensureWallet(
      profile,
      createWalletIfMissing: createWalletIfMissing,
    );
    await _syncBinding(user, profile, walletId);
  }

  Future<Map<String, dynamic>> _requireUnifiedIdentity() async {
    try {
      return await BigKAuthService().syncProfile();
    } catch (e) {
      if (e is ApiException && (e.code == 401 || e.code == 403)) {
        await BigKAuthService().logout();
        throw ApiException(
          401,
          'Unified identity session has expired. Please login again.',
        );
      }

      if (e is ApiException) {
        throw ApiException(
            e.code, 'Mall session validation failed: ${e.message}');
      }
      throw ApiException(-1, 'Mall session validation failed: $e');
    }
  }

  Future<String> _ensureWallet(
    Map<String, dynamic> profile, {
    required bool createWalletIfMissing,
  }) async {
    final currentWalletId = profile['wallet_id']?.toString() ?? '';
    if (currentWalletId.isNotEmpty) {
      return currentWalletId;
    }

    if (!createWalletIfMissing) {
      throw const MallWalletProvisionRequiredException();
    }

    final provisionedWalletId = await BigKAuthService().provisionWallet();
    final refreshedProfile = await BigKAuthService().syncProfile();
    final refreshedWalletId = refreshedProfile['wallet_id']?.toString() ?? '';
    final resolvedWalletId = refreshedWalletId.isNotEmpty
        ? refreshedWalletId
        : (provisionedWalletId ?? '');

    if (resolvedWalletId.isEmpty) {
      throw ApiException(500, 'Wallet provisioning failed.');
    }

    debugPrint('ShopSessionService: wallet provisioned for KCC identity');
    return resolvedWalletId;
  }

  Future<void> _syncBinding(
    User user,
    Map<String, dynamic> profile,
    String walletId,
  ) async {
    final kccUserId = profile['sub']?.toString() ?? '';
    final mallEmail = profile['email']?.toString() ?? '';
    final mallHandle = profile['preferred_username']?.toString() ?? '';
    final mallDisplayName = profile['name']?.toString() ?? '';
    final binding = user.mallBinding;

    final needsSync = !binding.isBound ||
        binding.kccUserId != kccUserId ||
        binding.mallEmail != mallEmail ||
        binding.mallHandle != mallHandle ||
        binding.mallDisplayName != mallDisplayName ||
        binding.mallClientId != BigKAuthService.walletClientId ||
        binding.mallWalletId != walletId;

    if (!needsSync) {
      return;
    }

    await UserService().syncMallBinding(
      kccUserId: kccUserId,
      mallEmail: mallEmail,
      mallHandle: mallHandle,
      mallDisplayName: mallDisplayName,
      mallClientId: BigKAuthService.walletClientId,
      mallWalletId: walletId,
    );

    debugPrint('ShopSessionService: local mall binding synced from KCC');
  }
}
