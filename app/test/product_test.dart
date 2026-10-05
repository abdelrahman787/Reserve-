import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/features/catalog/data/models/product.dart';

void main() {
  group('Offer', () {
    test('effectivePrice applies the discount', () {
      const o = Offer(
        vendorId: 'v',
        price: 100,
        discountPercent: 10,
        stockQty: 5,
        isAvailable: true,
      );
      expect(o.effectivePrice, 90);
    });
  });

  group('Product', () {
    test('bestOffer picks the cheapest available, in-stock offer', () {
      const p = Product(
        id: '1',
        tradeName: 'X',
        offers: [
          Offer(
              vendorId: 'a',
              price: 100,
              discountPercent: 0,
              stockQty: 5,
              isAvailable: true),
          Offer(
              vendorId: 'b',
              price: 80,
              discountPercent: 0,
              stockQty: 5,
              isAvailable: true),
          Offer(
              vendorId: 'c',
              price: 50,
              discountPercent: 0,
              stockQty: 0, // out of stock -> excluded
              isAvailable: true),
        ],
      );
      expect(p.bestOffer?.vendorId, 'b');
      expect(p.lowestPrice, 80);
      expect(p.inStock, isTrue);
    });

    test('inStock is false when no offer is available or in stock', () {
      const p = Product(
        id: '1',
        tradeName: 'X',
        offers: [
          Offer(
              vendorId: 'a',
              price: 100,
              discountPercent: 0,
              stockQty: 0,
              isAvailable: true),
          Offer(
              vendorId: 'b',
              price: 80,
              discountPercent: 0,
              stockQty: 5,
              isAvailable: false),
        ],
      );
      expect(p.inStock, isFalse);
      expect(p.lowestPrice, isNull);
    });

    test('fromMap parses nested vendor_products and computes best price', () {
      final p = Product.fromMap(const {
        'id': '1',
        'trade_name': 'Panadol',
        'generic_name': 'Paracetamol',
        'vendor_products': [
          {
            'id': 'vp1',
            'vendor_id': 'v1',
            'price': 28.5,
            'discount_percent': 10,
            'stock_qty': 100,
            'is_available': true,
          }
        ],
      });
      expect(p.tradeName, 'Panadol');
      expect(p.genericName, 'Paracetamol');
      expect(p.offers.length, 1);
      expect(p.bestOffer?.vendorProductId, 'vp1');
      expect(p.lowestPrice, closeTo(25.65, 0.001));
    });
  });
}
