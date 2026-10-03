import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';

/// A line in the cart, joined with its product + offer for display.
class CartLine {
  CartLine({
    required this.id,
    required this.vendorProductId,
    required this.quantity,
    required this.productName,
    required this.unitPrice,
  });

  final String id;
  final String vendorProductId;
  final int quantity;
  final String productName;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;

  factory CartLine.fromMap(Map<String, dynamic> m) {
    final vp = (m['vendor_products'] as Map<String, dynamic>?) ?? const {};
    final product = (vp['products'] as Map<String, dynamic>?) ?? const {};
    final price = (vp['price'] as num?)?.toDouble() ?? 0;
    final disc = (vp['discount_percent'] as num?)?.toDouble() ?? 0;
    return CartLine(
      id: m['id'] as String,
      vendorProductId: m['vendor_product_id'] as String,
      quantity: (m['quantity'] as num).toInt(),
      productName: product['trade_name'] as String? ?? '—',
      unitPrice: price * (1 - disc / 100),
    );
  }
}

class CartRepository {
  CartRepository(this._client);
  final SupabaseClient _client;

  /// Returns the pharmacy's active cart id, creating one if needed.
  Future<String> _ensureCart(String pharmacyId) async {
    final existing = await _client
        .from('carts')
        .select('id')
        .eq('pharmacy_id', pharmacyId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final created = await _client
        .from('carts')
        .insert({'pharmacy_id': pharmacyId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  Future<Either<Failure, List<CartLine>>> fetchItems(String pharmacyId) async {
    try {
      final cartId = await _ensureCart(pharmacyId);
      final rows = await _client
          .from('cart_items')
          .select(
              'id, vendor_product_id, quantity, vendor_products(price, discount_percent, products(trade_name))')
          .eq('cart_id', cartId);
      final lines = (rows as List)
          .map((e) => CartLine.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(lines);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> addItem({
    required String pharmacyId,
    required String vendorProductId,
    int quantity = 1,
  }) async {
    try {
      final cartId = await _ensureCart(pharmacyId);
      await _client.from('cart_items').upsert({
        'cart_id': cartId,
        'vendor_product_id': vendorProductId,
        'quantity': quantity,
      }, onConflict: 'cart_id,vendor_product_id');
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> removeItem(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
