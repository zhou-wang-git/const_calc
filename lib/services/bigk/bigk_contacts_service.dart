import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_contacts.dart';
import '../../dto/bigk/bigk_json.dart';
import 'bigk_http_service.dart';

class BigKContactsService {
  static Future<BigKContactPage> getContacts({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint('BigKContactsService: Fetching contacts...');

    return BigKHttpService.getWallet<BigKContactPage>(
      '/app/contacts',
      (data) => BigKContactPage.fromJson(
        data,
        preferredKey: 'contacts',
      ),
      queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<BigKContactPage> getSavedWallets({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint('BigKContactsService: Fetching saved wallets...');

    return BigKHttpService.getWallet<BigKContactPage>(
      '/app/saved-wallets',
      (data) => BigKContactPage.fromJson(
        data,
        preferredKey: 'saved_wallets',
      ),
      queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<BigKContact> createSavedWallet({
    String walletId = '',
    String handle = '',
    String alias = '',
  }) async {
    debugPrint('BigKContactsService: Creating saved wallet...');

    return BigKHttpService.postWallet<BigKContact>(
      '/app/saved-wallets',
      <String, dynamic>{
        if (walletId.trim().isNotEmpty) 'wallet_id': walletId.trim(),
        if (handle.trim().isNotEmpty) 'handle': handle.trim(),
        if (alias.trim().isNotEmpty) 'alias': alias.trim(),
      },
      BigKContact.fromJson,
    );
  }

  static Future<BigKContact> updateSavedWallet(
    String id, {
    required String alias,
  }) async {
    debugPrint('BigKContactsService: Updating saved wallet $id...');

    return BigKHttpService.putWallet<BigKContact>(
      '/app/saved-wallets/$id',
      <String, dynamic>{
        'alias': alias.trim(),
      },
      BigKContact.fromJson,
    );
  }

  static Future<void> deleteSavedWallet(String id) async {
    debugPrint('BigKContactsService: Deleting saved wallet $id...');

    await BigKHttpService.deleteWallet<Map<String, dynamic>>(
      '/app/saved-wallets/$id',
      (data) => bigkAsMap(data),
    );
  }
}
