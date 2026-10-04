import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';
import 'models/promo_row.dart';
import 'models/vendor_product_row.dart';

class AdminRepository {
  AdminRepository(this._client);
  final SupabaseClient _client;

  Future<Either<Failure, List<VendorProductRow>>> fetchVendorProducts(
      String vendorId) async {
    try {
      final rows = await _client
          .from('vendor_products')
          .select('*, products(trade_name, generic_name)')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      final list = (rows as List)
          .map((e) => VendorProductRow.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> updateVendorProduct(
    String id, {
    double? price,
    double? discountPercent,
    int? stockQty,
    bool? isAvailable,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (price != null) patch['price'] = price;
      if (discountPercent != null) patch['discount_percent'] = discountPercent;
      if (stockQty != null) patch['stock_qty'] = stockQty;
      if (isAvailable != null) patch['is_available'] = isAvailable;
      if (patch.isEmpty) return const Right(unit);
      await _client.from('vendor_products').update(patch).eq('id', id);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Creates a catalog product and the vendor's offer for it in one go.
  Future<Either<Failure, Unit>> createProductWithOffer({
    required String vendorId,
    required String tradeName,
    String? genericName,
    String? producer,
    required double price,
    int stockQty = 0,
  }) async {
    try {
      final product = await _client
          .from('products')
          .insert({
            'trade_name': tradeName,
            'generic_name': genericName,
            'producer': producer,
          })
          .select('id')
          .single();

      await _client.from('vendor_products').insert({
        'vendor_id': vendorId,
        'product_id': product['id'],
        'price': price,
        'stock_qty': stockQty,
      });
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // --- Promos ---------------------------------------------------------------

  Future<Either<Failure, List<PromoRow>>> fetchPromos(String vendorId) async {
    try {
      final rows = await _client
          .from('promos')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      final list = (rows as List)
          .map((e) => PromoRow.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> createPromo({
    required String vendorId,
    required String code,
    required String dType,
    required double dValue,
    double minOrder = 0,
    String? description,
  }) async {
    try {
      await _client.from('promos').insert({
        'vendor_id': vendorId,
        'code': code,
        'd_type': dType,
        'd_value': dValue,
        'min_order': minOrder,
        'description': description,
      });
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> setPromoActive(String id, bool active) async {
    try {
      await _client.from('promos').update({'is_active': active}).eq('id', id);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
