import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_json.dart';
import '../../dto/bigk/bigk_message.dart';
import 'bigk_http_service.dart';

class BigKInboxService {
  static Future<BigKMessagePage> getInbox({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint('BigKInboxService: Fetching inbox...');

    return BigKHttpService.getWallet<BigKMessagePage>(
      '/app/inbox',
      (data) => BigKMessagePage.fromJson(data, preferredKey: 'messages'),
      queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<int> getUnreadCount() async {
    debugPrint('BigKInboxService: Fetching unread count...');

    return BigKHttpService.getWallet<int>(
      '/app/inbox/unread-count',
      (data) {
        final payload = bigkUnwrapMap(data);
        return bigkInt(
          payload,
          const ['count', 'unread_count', 'total'],
        );
      },
    );
  }

  static Future<void> markInboxRead(String id) async {
    debugPrint('BigKInboxService: Marking inbox item $id read...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/inbox/$id/read',
      const <String, dynamic>{},
      bigkAsMap,
    );
  }

  static Future<void> markAllInboxRead() async {
    debugPrint('BigKInboxService: Marking all inbox items read...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/inbox/read-all',
      const <String, dynamic>{},
      bigkAsMap,
    );
  }

  static Future<void> markInboxBulkRead(List<String> ids) async {
    debugPrint('BigKInboxService: Marking inbox items read in bulk...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/inbox/bulk/read',
      <String, dynamic>{'ids': ids},
      bigkAsMap,
    );
  }

  static Future<void> deleteInboxMessage(String id) async {
    debugPrint('BigKInboxService: Deleting inbox item $id...');
    await BigKHttpService.deleteWallet<Map<String, dynamic>>(
      '/app/inbox/$id',
      bigkAsMap,
    );
  }

  static Future<void> deleteInboxBulk(List<String> ids) async {
    debugPrint('BigKInboxService: Deleting inbox items in bulk...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/inbox/bulk/delete',
      <String, dynamic>{'ids': ids},
      bigkAsMap,
    );
  }

  static Future<BigKMessagePage> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint('BigKInboxService: Fetching notifications...');

    return BigKHttpService.getWallet<BigKMessagePage>(
      '/app/notifications',
      (data) => BigKMessagePage.fromJson(data, preferredKey: 'notifications'),
      queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<void> markNotificationRead(String id) async {
    debugPrint('BigKInboxService: Marking notification $id read...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/notifications/$id/read',
      const <String, dynamic>{},
      bigkAsMap,
    );
  }

  static Future<void> markAllNotificationsRead() async {
    debugPrint('BigKInboxService: Marking all notifications read...');
    await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/app/notifications/read-all',
      const <String, dynamic>{},
      bigkAsMap,
    );
  }
}
