import 'package:equatable/equatable.dart';

/// A single vendor's offer (price + stock) for a product.
class Offer extends Equatable {
  const Offer({
    required this.vendorId,
    required this.price,
    required this.discountPercent,
    required this.stockQty,
    required this.isAvailable,
    this.vendorProductId,
  });

  final String vendorId;
  final String? vendorProductId;
  final double price;
  final double discountPercent;
  final int stockQty;
  final bool isAvailable;

  double get effectivePrice => price * (1 - discountPercent / 100);

  factory Offer.fromMap(Map<String, dynamic> m) => Offer(
        vendorId: m['vendor_id'] as String,
        vendorProductId: m['id'] as String?,
        price: (m['price'] as num).toDouble(),
        discountPercent: (m['discount_percent'] as num?)?.toDouble() ?? 0,
        stockQty: (m['stock_qty'] as num?)?.toInt() ?? 0,
        isAvailable: m['is_available'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [vendorProductId, vendorId, price];
}

/// A drug in the shared catalog, with its available vendor offers.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.tradeName,
    this.genericName,
    this.pharmacology,
    this.producer,
    this.description,
    this.indications,
    this.dosage,
    this.imageUrl,
    this.requiresRx = false,
    this.offers = const [],
  });

  final String id;
  final String tradeName;
  final String? genericName;
  final String? pharmacology;
  final String? producer;
  final String? description;
  final String? indications;
  final String? dosage;
  final String? imageUrl;
  final bool requiresRx;
  final List<Offer> offers;

  /// Cheapest available offer, if any.
  Offer? get bestOffer {
    final available = offers.where((o) => o.isAvailable && o.stockQty > 0);
    if (available.isEmpty) return null;
    return available.reduce(
        (a, b) => a.effectivePrice <= b.effectivePrice ? a : b);
  }

  double? get lowestPrice => bestOffer?.effectivePrice;
  bool get inStock => bestOffer != null;

  factory Product.fromMap(Map<String, dynamic> m) {
    final rawOffers = (m['vendor_products'] as List?) ?? const [];
    return Product(
      id: m['id'] as String,
      tradeName: m['trade_name'] as String,
      genericName: m['generic_name'] as String?,
      pharmacology: m['pharmacology'] as String?,
      producer: m['producer'] as String?,
      description: m['description'] as String?,
      indications: m['indications'] as String?,
      dosage: m['dosage'] as String?,
      imageUrl: m['image_url'] as String?,
      requiresRx: m['requires_rx'] as bool? ?? false,
      offers: rawOffers
          .map((e) => Offer.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, tradeName, offers];
}
