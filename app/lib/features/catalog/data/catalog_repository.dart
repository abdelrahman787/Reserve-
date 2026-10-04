import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';
import 'models/category.dart';
import 'models/product.dart';

class CatalogRepository {
  CatalogRepository(this._client);
  final SupabaseClient _client;

  Future<Either<Failure, List<Category>>> fetchCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      final list = (rows as List)
          .map((e) => Category.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  static const _select =
      '*, vendor_products(id, vendor_id, price, discount_percent, stock_qty, is_available)';

  Future<Either<Failure, List<Product>>> fetchProducts({
    String? search,
    String? categoryId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('products').select(_select);

      if (search != null && search.trim().isNotEmpty) {
        final q = '%${search.trim()}%';
        query = query.or('trade_name.ilike.$q,generic_name.ilike.$q,producer.ilike.$q');
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('trade_name', ascending: true)
          .range(offset, offset + limit - 1);

      final products = (rows as List)
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(products);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Product>> fetchProduct(String id) async {
    try {
      final row =
          await _client.from('products').select(_select).eq('id', id).single();
      return Right(Product.fromMap(row));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
