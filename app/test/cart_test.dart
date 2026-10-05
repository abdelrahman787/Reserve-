import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/features/cart/data/cart_repository.dart';

void main() {
  test('CartLine.fromMap parses nested product + discounted unit price', () {
    final line = CartLine.fromMap(const {
      'id': 'ci1',
      'vendor_product_id': 'vp1',
      'quantity': 3,
      'vendor_products': {
        'price': 100.0,
        'discount_percent': 25.0,
        'products': {'trade_name': 'Cevamin'},
      },
    });
    expect(line.productName, 'Cevamin');
    expect(line.quantity, 3);
    expect(line.unitPrice, 75.0); // 100 - 25%
    expect(line.lineTotal, 225.0); // 75 * 3
  });
}
