import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/features/cart/data/cart_repository.dart';
import 'package:pharma_reserve/features/cart/presentation/cubit/cart_cubit.dart';

CartLine _line(int qty, double price) => CartLine(
      id: 'l$qty',
      vendorProductId: 'vp',
      quantity: qty,
      productName: 'X',
      unitPrice: price,
    );

void main() {
  test('CartState aggregates count and total across lines', () {
    final state = CartState.loaded([_line(2, 10), _line(3, 5)]);
    expect(state.count, 5); // 2 + 3
    expect(state.total, 35); // 2*10 + 3*5
  });

  test('empty cart has zero count and total', () {
    const state = CartState.loaded([]);
    expect(state.count, 0);
    expect(state.total, 0);
  });
}
