import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/features/orders/data/models/order.dart';

void main() {
  test('OrderItem.fromMap parses fields', () {
    final it = OrderItem.fromMap(const {
      'product_name': 'Augmentin',
      'unit_price': 95.0,
      'quantity': 2,
      'line_total': 190.0,
    });
    expect(it.productName, 'Augmentin');
    expect(it.quantity, 2);
    expect(it.lineTotal, 190.0);
  });

  test('PharmaOrder.fromMap parses vendor + items + totals', () {
    final o = PharmaOrder.fromMap(const {
      'id': 'o1',
      'pharmacy_id': 'ph1',
      'status': 'processing',
      'subtotal': 200.0,
      'discount': 20.0,
      'delivery_fee': 0.0,
      'total': 180.0,
      'created_at': '2026-01-01T10:00:00Z',
      'vendors': {'name': 'Nile Pharma'},
      'order_items': [
        {
          'product_name': 'Panadol',
          'unit_price': 28.5,
          'quantity': 2,
          'line_total': 57.0,
        }
      ],
    });
    expect(o.id, 'o1');
    expect(o.pharmacyId, 'ph1');
    expect(o.status, 'processing');
    expect(o.vendorName, 'Nile Pharma');
    expect(o.total, 180.0);
    expect(o.items.single.productName, 'Panadol');
  });

  test('PharmaOrder.fromMap tolerates missing optional fields', () {
    final o = PharmaOrder.fromMap(const {'id': 'o2'});
    expect(o.status, 'pending');
    expect(o.total, 0);
    expect(o.items, isEmpty);
    expect(o.vendorName, isNull);
  });
}
