class VendorProductRow {
  VendorProductRow({
    required this.id,
    required this.productId,
    required this.tradeName,
    required this.price,
    required this.discountPercent,
    required this.stockQty,
    required this.isAvailable,
    this.genericName,
    this.imageUrl,
  });

  final String id;
  final String productId;
  final String tradeName;
  final String? genericName;
  final double price;
  final double discountPercent;
  final int stockQty;
  final bool isAvailable;
  final String? imageUrl;

  factory VendorProductRow.fromMap(Map<String, dynamic> m) {
    final product = (m['products'] as Map<String, dynamic>?) ?? const {};
    return VendorProductRow(
      id: m['id'] as String,
      productId: m['product_id'] as String,
      tradeName: product['trade_name'] as String? ?? '—',
      genericName: product['generic_name'] as String?,
      imageUrl: product['image_url'] as String?,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      discountPercent: (m['discount_percent'] as num?)?.toDouble() ?? 0,
      stockQty: (m['stock_qty'] as num?)?.toInt() ?? 0,
      isAvailable: m['is_available'] as bool? ?? true,
    );
  }
}
