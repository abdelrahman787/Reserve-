import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/features/catalog/data/models/category.dart';

void main() {
  test('Category.fromMap parses names and id', () {
    final c = Category.fromMap(const {
      'id': 'cat1',
      'name_en': 'Medications',
      'name_ar': 'أدوية',
    });
    expect(c.id, 'cat1');
    expect(c.name(false), 'Medications');
    expect(c.name(true), 'أدوية');
  });

  test('Category.fromMap tolerates missing names', () {
    final c = Category.fromMap(const {'id': 'cat2'});
    expect(c.name(false), '');
    expect(c.name(true), '');
  });
}
