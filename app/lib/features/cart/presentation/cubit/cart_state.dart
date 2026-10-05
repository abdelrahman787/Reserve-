part of 'cart_cubit.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  const CartState._(this.status, {this.items = const [], this.message});

  const CartState.initial() : this._(CartStatus.initial);
  const CartState.loaded(List<CartLine> items)
      : this._(CartStatus.loaded, items: items);
  const CartState.error(String message)
      : this._(CartStatus.error, message: message);

  final CartStatus status;
  final List<CartLine> items;
  final String? message;

  CartState copyWith({CartStatus? status, List<CartLine>? items}) =>
      CartState._(status ?? this.status,
          items: items ?? this.items, message: message);

  int get count => items.fold(0, (sum, e) => sum + e.quantity);
  double get total => items.fold(0, (sum, e) => sum + e.lineTotal);

  @override
  List<Object?> get props => [status, items, message];
}
