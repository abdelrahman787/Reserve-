import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/order.dart';
import '../../data/orders_repository.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo) : super(const OrdersState.initial());
  final OrdersRepository _repo;

  Future<void> load() async {
    emit(const OrdersState.loading());
    final res = await _repo.fetchOrders();
    res.fold(
      (f) => emit(OrdersState.error(f.message)),
      (orders) => emit(OrdersState.loaded(orders)),
    );
  }
}
