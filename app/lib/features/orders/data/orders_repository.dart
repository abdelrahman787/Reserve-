import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';
import 'models/order.dart';

class OrdersRepository {
  OrdersRepository(this._client);
  final SupabaseClient _client;

  Future<Either<Failure, List<PharmaOrder>>> fetchOrders() async {
    try {
      final rows = await _client
          .from('orders')
          .select('*, vendors(name)')
          .order('created_at', ascending: false);
      final orders = (rows as List)
          .map((e) => PharmaOrder.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(orders);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, PharmaOrder>> fetchOrder(String id) async {
    try {
      final row = await _client
          .from('orders')
          .select('*, vendors(name), order_items(*)')
          .eq('id', id)
          .single();
      return Right(PharmaOrder.fromMap(row));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Updates an order's status (vendor/admin only — enforced by RLS).
  Future<Either<Failure, Unit>> updateStatus(
      String orderId, String status) async {
    try {
      final patch = <String, dynamic>{'status': status};
      if (status == 'delivered') {
        patch['delivered_at'] = DateTime.now().toUtc().toIso8601String();
      }
      await _client.from('orders').update(patch).eq('id', orderId);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Calls the `checkout` RPC; returns the created order ids.
  Future<Either<Failure, List<String>>> checkout({
    String? note,
    String? promoCode,
  }) async {
    try {
      final res = await _client.rpc('checkout', params: {
        'p_note': note,
        'p_promo_code': promoCode,
      });
      final ids = (res as List).map((e) => e.toString()).toList();
      return Right(ids);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
