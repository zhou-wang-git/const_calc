import 'package:flutter/material.dart';

import '../dto/bigk/bigk_order.dart';
import 'auth_service.dart';
import 'bigk/bigk_checkout_service.dart';
import 'cart_service.dart';

class ShopOrder {
  final int id;
  final String orderKey;
  final String status;
  final String total;
  final String currency;
  final DateTime createdAt;
  final List<ShopOrderItem> items;

  ShopOrder({
    required this.id,
    required this.orderKey,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.items,
  });

  String get number => orderKey;

  String get dateCreated =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

  String get statusText {
    switch (status) {
      case 'pending':
        return '待付款';
      case 'processing':
        return '处理中';
      case 'on-hold':
        return '待收货';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'refunded':
        return '已退款';
      case 'failed':
        return '支付失败';
      default:
        return status;
    }
  }
}

class ShopOrderItem {
  final int id;
  final String name;
  final int quantity;
  final String total;
  final String price;
  final String? image;

  ShopOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.total,
    required this.price,
    this.image,
  });
}

class ShopOrderService {
  static Future<bool> createOrderAndPay(BuildContext context) async {
    final user = AuthService().loginUser;
    if (user == null) {
      throw Exception('请先登录');
    }

    final cart = await CartService.getCart();
    if (cart.isEmpty) {
      throw Exception('购物车为空');
    }

    throw Exception(
      '当前商城下单暂不可用：PlenorHub 结算接口仍返回 Wallet not found，需客户先修复 KCC 钱包绑定后再开放支付。',
    );
  }

  static Future<List<ShopOrder>> getOrders({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final response = await BigKCheckoutService.getOrders(
      page: page,
      perPage: perPage,
    );

    final orders = response.data.map(_mapOrder).toList(growable: false);
    if (status == null || status.isEmpty) {
      return orders;
    }

    return orders
        .where((order) => order.status == status)
        .toList(growable: false);
  }

  static Future<ShopOrder?> getOrder(int orderId) async {
    final order = await BigKCheckoutService.getOrder(orderId);
    return _mapOrder(order);
  }

  static Future<bool> cancelOrder(int orderId) async {
    return false;
  }

  static ShopOrder _mapOrder(BigKOrder order) {
    final items = order.items.map(_mapOrderItem).toList(growable: false);
    final normalizedItems = items.isEmpty
        ? [
            ShopOrderItem(
              id: 0,
              name: order.itemName ?? '商品',
              quantity: order.quantity,
              total: _formatAmount(order.totalAmount),
              price: _formatAmount(order.totalAmount),
              image: null,
            ),
          ]
        : items;

    return ShopOrder(
      id: order.id,
      orderKey: order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString(),
      status: _normalizeStatus(order),
      total: _formatAmount(order.totalAmount),
      currency: order.currency,
      createdAt: order.placedAt ?? DateTime.now(),
      items: normalizedItems,
    );
  }

  static ShopOrderItem _mapOrderItem(Map<String, dynamic> item) {
    final quantity = _asInt(item['qty'] ?? item['quantity'], 1);
    final price = _asDouble(
      item['unit_price'] ?? item['price'] ?? item['amount'],
      0,
    );
    final total = _asDouble(
      item['line_total'] ?? item['total'] ?? item['subtotal'],
      price * quantity,
    );

    return ShopOrderItem(
      id: _asInt(item['product_id'] ?? item['id'], 0),
      name:
          item['name']?.toString() ?? item['product_name']?.toString() ?? '商品',
      quantity: quantity,
      total: _formatAmount(total),
      price: _formatAmount(price),
      image: _extractImage(item),
    );
  }

  static String _normalizeStatus(BigKOrder order) {
    if (order.paymentStatus == 'failed') {
      return 'failed';
    }
    if (order.paymentStatus == 'refunded') {
      return 'refunded';
    }
    if (order.state == 'cancelled') {
      return 'cancelled';
    }
    if (order.paymentStatus == 'pending') {
      return 'pending';
    }

    switch (order.state) {
      case 'dispatched':
        return 'on-hold';
      case 'delivered':
        return 'completed';
      case 'confirmed':
      case 'processing':
        return 'processing';
      default:
        return order.paymentStatus == 'paid' ? 'processing' : 'pending';
    }
  }

  static String? _extractImage(Map<String, dynamic> item) {
    final direct = item['image_url'] ?? item['product_image'] ?? item['image'];
    if (direct is String && direct.isNotEmpty) {
      return direct;
    }
    if (direct is Map) {
      final src = direct['src']?.toString();
      if (src != null && src.isNotEmpty) {
        return src;
      }
    }

    final product = item['product'];
    if (product is Map) {
      final imageUrl = product['image_url']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    return null;
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }
}
