import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/order.dart';
import '../../data/orders_repository.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo, this._client) : super(const OrdersState.initial()) {
    _subscribeRealtime();
  }

  final OrdersRepository _repo;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  Future<void> load() async {
    emit(const OrdersState.loading());
    final res = await _repo.fetchOrders();
    res.fold(
      (f) => emit(OrdersState.error(f.message)),
      (orders) => emit(OrdersState.loaded(orders)),
    );
  }

  /// Live-refresh the list whenever an order row changes (status updates, new
  /// orders). Requires Realtime to be enabled for the `orders` table in
  /// Supabase; if it is not, this is simply a no-op.
  void _subscribeRealtime() {
    _channel = _client
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => load(),
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    final channel = _channel;
    if (channel != null) _client.removeChannel(channel);
    return super.close();
  }
}
