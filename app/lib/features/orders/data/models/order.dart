import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productName: m['product_name'] as String? ?? '—',
        unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        lineTotal: (m['line_total'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [productName, unitPrice, quantity, lineTotal];
}

class PharmaOrder extends Equatable {
  const PharmaOrder({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.vendorName,
    this.promoCode,
    this.note,
    this.deliveredAt,
    this.items = const [],
  });

  final String id;
  final String status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final String? vendorName;
  final String? promoCode;
  final String? note;
  final DateTime? deliveredAt;
  final List<OrderItem> items;

  factory PharmaOrder.fromMap(Map<String, dynamic> m) {
    final vendor = m['vendors'] as Map<String, dynamic>?;
    final rawItems = (m['order_items'] as List?) ?? const [];
    return PharmaOrder(
      id: m['id'] as String,
      status: m['status'] as String? ?? 'pending',
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (m['discount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (m['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      vendorName: vendor?['name'] as String?,
      promoCode: m['promo_code'] as String?,
      note: m['note'] as String?,
      deliveredAt: m['delivered_at'] != null
          ? DateTime.tryParse(m['delivered_at'] as String)
          : null,
      items:
          rawItems.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [id, status, total];
}
