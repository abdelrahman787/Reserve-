part of 'orders_cubit.dart';

enum OrdersStatus { initial, loading, loaded, error }

class OrdersState extends Equatable {
  const OrdersState._(this.status, {this.orders = const [], this.message});

  const OrdersState.initial() : this._(OrdersStatus.initial);
  const OrdersState.loading() : this._(OrdersStatus.loading);
  const OrdersState.loaded(List<PharmaOrder> orders)
      : this._(OrdersStatus.loaded, orders: orders);
  const OrdersState.error(String message)
      : this._(OrdersStatus.error, message: message);

  final OrdersStatus status;
  final List<PharmaOrder> orders;
  final String? message;

  @override
  List<Object?> get props => [status, orders, message];
}
