Map<String, dynamic> bigkAsMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> bigkAsList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}

Map<String, dynamic> bigkUnwrapMap(
  dynamic value, {
  String? preferredKey,
}) {
  final map = bigkAsMap(value);
  if (preferredKey != null && map[preferredKey] != null) {
    return bigkAsMap(map[preferredKey]);
  }
  if (map['data'] != null) {
    final dataMap = bigkAsMap(map['data']);
    if (dataMap.isNotEmpty) {
      return dataMap;
    }
  }
  return map;
}

List<dynamic> bigkUnwrapList(
  dynamic value, {
  String? preferredKey,
}) {
  final map = bigkAsMap(value);
  if (preferredKey != null && map[preferredKey] != null) {
    return bigkAsList(map[preferredKey]);
  }
  if (map['data'] != null) {
    final data = map['data'];
    if (data is List) {
      return data;
    }
    final dataMap = bigkAsMap(data);
    for (final key in _bigkListKeys) {
      if (dataMap[key] is List) {
        return bigkAsList(dataMap[key]);
      }
    }
  }
  for (final key in _bigkListKeys) {
    if (map[key] is List) {
      return bigkAsList(map[key]);
    }
  }
  if (value is List) {
    return value;
  }
  return const [];
}

String bigkString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    final text = value?.toString() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}

bool bigkBool(
  Map<String, dynamic> map,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }
  return fallback;
}

int bigkInt(
  Map<String, dynamic> map,
  List<String> keys, {
  int fallback = 0,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

double bigkDouble(
  Map<String, dynamic> map,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

DateTime? bigkDateTime(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

const List<String> _bigkListKeys = <String>[
  'items',
  'rows',
  'results',
  'messages',
  'notifications',
  'contacts',
  'saved_wallets',
  'savedWallets',
  'sessions',
  'rates',
  'currencies',
  'data',
];
