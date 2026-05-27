import 'bigk_json.dart';

class BigKMessageItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const BigKMessageItem({
    this.id = '',
    this.title = '',
    this.body = '',
    this.type = '',
    this.isRead = false,
    this.createdAt,
  });

  factory BigKMessageItem.fromJson(dynamic json) {
    final data = bigkAsMap(json);
    return BigKMessageItem(
      id: bigkString(data, const ['id', 'message_id', 'notification_id']),
      title: bigkString(data, const ['title', 'subject', 'heading']),
      body: bigkString(
        data,
        const ['body', 'message', 'content', 'description'],
      ),
      type: bigkString(data, const ['type', 'category']),
      isRead: bigkBool(
        data,
        const ['is_read', 'read', 'seen'],
      ),
      createdAt: bigkDateTime(
        data,
        const ['created_at', 'sent_at', 'updated_at'],
      ),
    );
  }
}

class BigKMessagePage {
  final List<BigKMessageItem> items;
  final int page;
  final int perPage;
  final int total;

  const BigKMessagePage({
    this.items = const <BigKMessageItem>[],
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
  });

  factory BigKMessagePage.fromJson(
    dynamic json, {
    String? preferredKey,
  }) {
    final data = bigkAsMap(json);
    final list = bigkUnwrapList(data, preferredKey: preferredKey);
    final payload = bigkUnwrapMap(data);
    return BigKMessagePage(
      items: list.map(BigKMessageItem.fromJson).toList(),
      page: bigkInt(payload, const ['page', 'current_page'], fallback: 1),
      perPage: bigkInt(
        payload,
        const ['per_page', 'page_size'],
        fallback: list.isEmpty ? 20 : list.length,
      ),
      total: bigkInt(
        payload,
        const ['total', 'total_count'],
        fallback: list.length,
      ),
    );
  }
}
