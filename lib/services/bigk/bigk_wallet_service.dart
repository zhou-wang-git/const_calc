import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_transaction.dart';
import '../../dto/bigk/bigk_wallet.dart';
import 'bigk_http_service.dart';

class BigKWalletService {
  static BigKWallet? _cachedWallet;

  static Future<BigKWallet> getWallet({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedWallet != null) {
      return _cachedWallet!;
    }

    debugPrint('BigKWalletService: Fetching wallet profile...');

    final wallet = await BigKHttpService.getWallet<BigKWallet>(
      '/app/me',
      (data) => BigKWallet.fromJson(
        data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data['data'] is Map
                ? Map<String, dynamic>.from(data['data'] as Map)
                : Map<String, dynamic>.from(data as Map),
      ),
    );

    _cachedWallet = wallet;
    return wallet;
  }

  static BigKWallet? getCachedWallet() => _cachedWallet;

  static Future<BigKTransactionPage> getTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint(
      'BigKWalletService: Fetching wallet transactions page=$page perPage=$perPage...',
    );

    return BigKHttpService.getWallet<BigKTransactionPage>(
      '/app/transactions',
      (data) => BigKTransactionPage.fromJson(
        data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map),
      ),
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<BigKTransferResult> transfer({
    required String recipientHandle,
    required double amount,
    String? note,
  }) async {
    debugPrint(
      'BigKWalletService: Transferring $amount KCC to @$recipientHandle...',
    );

    final result = await BigKHttpService.postWallet<BigKTransferResult>(
      '/app/transfer',
      {
        'recipient_handle': recipientHandle,
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      (data) => BigKTransferResult.fromJson(
        data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map),
      ),
    );

    _cachedWallet = null;
    return result;
  }

  static void clearCache() {
    _cachedWallet = null;
  }
}
