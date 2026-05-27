/// BigK 交易记录
class BigKTransaction {
  final int id;
  final String? externalId;
  final String type;
  final double amount;
  final String status;
  final int? fromWalletId;
  final int? toWalletId;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime? postedAt;

  BigKTransaction({
    required this.id,
    this.externalId,
    required this.type,
    required this.amount,
    required this.status,
    this.fromWalletId,
    this.toWalletId,
    this.reference,
    this.metadata,
    this.postedAt,
  });

  factory BigKTransaction.fromJson(Map<String, dynamic> json) {
    return BigKTransaction(
      id: _parseInt(json['id']),
      externalId: json['external_id']?.toString(),
      type: json['type']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status']?.toString() ?? 'posted',
      fromWalletId: _parseNullableInt(json['from_wallet_id']),
      toWalletId: _parseNullableInt(json['to_wallet_id']),
      reference: json['reference']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata']
          : json['metadata'] is Map
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString())
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'type': type,
      'amount': amount,
      'status': status,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'reference': reference,
      'metadata': metadata,
      'posted_at': postedAt?.toIso8601String(),
    };
  }

  /// 是否是收入（转入）
  bool get isIncome =>
      type == 'transfer' && toWalletId != null && fromWalletId == null ||
      type == 'mint' ||
      type == 'reward';

  /// 是否是支出（转出）
  bool get isExpense =>
      type == 'transfer' && fromWalletId != null && toWalletId == null ||
      type == 'spend';

  /// 格式化金额（带符号）
  String get amountFormatted {
    final sign = isIncome ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)}';
  }

  /// 类型名称
  String get typeName {
    switch (type) {
      case 'transfer':
        return isIncome ? '转入' : '转出';
      case 'mint':
        return '充值';
      case 'reward':
        return '奖励';
      case 'spend':
        return '消费';
      default:
        return '其他';
    }
  }

  /// 状态名称
  String get statusName {
    switch (status) {
      case 'posted':
        return '已完成';
      case 'pending':
        return '处理中';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }

  /// 描述（从 metadata 获取）
  String? get description => metadata?['description'];

  /// 格式化时间
  String get postedAtFormatted {
    if (postedAt == null) return '';
    return '${postedAt!.year}-${postedAt!.month.toString().padLeft(2, '0')}-${postedAt!.day.toString().padLeft(2, '0')} '
        '${postedAt!.hour.toString().padLeft(2, '0')}:${postedAt!.minute.toString().padLeft(2, '0')}';
  }
}

/// BigK 交易记录分页响应
class BigKTransactionPage {
  final List<BigKTransaction> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  BigKTransactionPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory BigKTransactionPage.fromJson(Map<String, dynamic> json) {
    final pageData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;
    final dataList = pageData['data'] is List
        ? pageData['data'] as List<dynamic>
        : json['data'] is List
            ? json['data'] as List<dynamic>
            : <dynamic>[];
    final meta = pageData['meta'] ?? json['meta'] ?? pageData;

    return BigKTransactionPage(
      data: dataList
          .map((e) =>
              BigKTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      perPage: meta['per_page'] ?? 20,
      total: meta['total'] ?? dataList.length,
    );
  }

  /// 是否有更多数据
  bool get hasMore => currentPage < lastPage;

  /// 是否为空
  bool get isEmpty => data.isEmpty;
}

/// BigK 转账结果
class BigKTransferResult {
  final bool success;
  final String? message;
  final BigKTransaction? transaction;

  BigKTransferResult({
    required this.success,
    this.message,
    this.transaction,
  });

  factory BigKTransferResult.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;

    return BigKTransferResult(
      success: payload['success'] ?? json['success'] ?? true,
      message: payload['message']?.toString() ?? json['message']?.toString(),
      transaction: payload['transaction'] != null
          ? BigKTransaction.fromJson(
              Map<String, dynamic>.from(payload['transaction'] as Map),
            )
          : payload['data'] is Map
              ? BigKTransaction.fromJson(
                  Map<String, dynamic>.from(payload['data'] as Map),
                )
              : null,
    );
  }
}
