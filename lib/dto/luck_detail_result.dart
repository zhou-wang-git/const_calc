import 'dart:convert';

import 'package:const_calc/dto/wu_xing.dart';

import 'element_order.dart';
import 'name_val_pair.dart';

class LuckDetailResult {
  final Wuxing wuxing;
  final int mainwx;
  final String mainwxx;
  final List<ElementOrder> fullOrder;
  final List<NameValPair> list;

  LuckDetailResult({
    required this.wuxing,
    required this.mainwx,
    required this.mainwxx,
    required this.fullOrder,
    required this.list,
  });

  factory LuckDetailResult.fromJson(Map<String, dynamic> json) {
    return LuckDetailResult(
      wuxing: Wuxing.fromJson(json['wuxing'] ?? {}),
      mainwx: json['mainwx'] ?? 0,
      mainwxx: json['mainwxx'] ?? '',
      fullOrder: (json['fullOrder'] as List<dynamic>? ?? [])
          .map((e) => ElementOrder.fromJson(e))
          .toList(),
      list: (json['list'] as List<dynamic>? ?? [])
          .map((e) => NameValPair.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'wuxing': wuxing.toJson(),
    'mainwx': mainwx,
    'mainwxx': mainwxx,
    'fullOrder': fullOrder.map((e) => e.toJson()).toList(),
    'list': list.map((e) => e.toJson()).toList(),
  };

  static LuckDetailResult? fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return LuckDetailResult.fromJson(json.decode(jsonStr));
    } catch (_) {
      return null;
    }
  }
}
