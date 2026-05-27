import 'bigk_json.dart';

class BigKContact {
  final String id;
  final String walletId;
  final String handle;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String alias;
  final bool isFavorite;
  final DateTime? lastTransferAt;

  const BigKContact({
    this.id = '',
    this.walletId = '',
    this.handle = '',
    this.displayName = '',
    this.email = '',
    this.avatarUrl = '',
    this.alias = '',
    this.isFavorite = false,
    this.lastTransferAt,
  });

  factory BigKContact.fromJson(dynamic json) {
    final data = bigkAsMap(json);
    final wallet = data['wallet'] == null
        ? const <String, dynamic>{}
        : bigkAsMap(data['wallet']);

    return BigKContact(
      id: bigkString(data, const ['id', 'saved_wallet_id', 'contact_id']),
      walletId: bigkString(
        data,
        const ['wallet_id', 'external_id'],
        fallback: bigkString(
          wallet,
          const ['wallet_id', 'external_id', 'id'],
        ),
      ),
      handle: bigkString(
        data,
        const ['handle', 'username'],
        fallback: bigkString(wallet, const ['handle', 'username']),
      ),
      displayName: bigkString(
        data,
        const ['display_name', 'name'],
        fallback: bigkString(wallet, const ['display_name', 'name']),
      ),
      email: bigkString(
        data,
        const ['email'],
        fallback: bigkString(wallet, const ['email']),
      ),
      avatarUrl: bigkString(
        data,
        const ['avatar_url', 'avatar'],
        fallback: bigkString(wallet, const ['avatar_url', 'avatar']),
      ),
      alias: bigkString(data, const ['alias', 'label', 'nickname']),
      isFavorite: bigkBool(
        data,
        const ['is_favorite', 'favorite'],
      ),
      lastTransferAt: bigkDateTime(
        data,
        const ['last_transfer_at', 'updated_at', 'created_at'],
      ),
    );
  }

  String get title {
    if (alias.isNotEmpty) {
      return alias;
    }
    if (displayName.isNotEmpty) {
      return displayName;
    }
    if (handle.isNotEmpty) {
      return '@$handle';
    }
    if (email.isNotEmpty) {
      return email;
    }
    return walletId;
  }

  String get subtitle {
    final parts = <String>[
      if (handle.isNotEmpty) '@$handle',
      if (email.isNotEmpty) email,
      if (walletId.isNotEmpty) walletId,
    ];
    return parts.join('  ');
  }
}

class BigKContactPage {
  final List<BigKContact> items;
  final int page;
  final int perPage;
  final int total;

  const BigKContactPage({
    this.items = const <BigKContact>[],
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
  });

  factory BigKContactPage.fromJson(
    dynamic json, {
    String preferredKey = 'contacts',
  }) {
    final data = bigkAsMap(json);
    final list = bigkUnwrapList(data, preferredKey: preferredKey);
    final payload = bigkUnwrapMap(data);
    return BigKContactPage(
      items: list.map(BigKContact.fromJson).toList(),
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
