import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/session/session_service.dart';
import '../../data/cart_repository.dart';

part 'cart_state.dart';

/// Shared cart state (registered as a singleton) so the cart page, the
/// product page's add-to-cart, and the nav-bar badge all stay in sync.
class CartCubit extends Cubit<CartState> {
  CartCubit(this._repo, this._session) : super(const CartState.initial());

  final CartRepository _repo;
  final SessionService _session;

  Future<void> load() async {
    final pharmacyId = await _session.pharmacyId();
    if (pharmacyId == null) {
      emit(const CartState.loaded([]));
      return;
    }
    emit(state.copyWith(status: CartStatus.loading));
    final res = await _repo.fetchItems(pharmacyId);
    res.fold(
      (f) => emit(CartState.error(f.message)),
      (items) => emit(CartState.loaded(items)),
    );
  }

  Future<String?> _pharmacyId() => _session.pharmacyId();

  Future<bool> add(String vendorProductId, {int quantity = 1}) async {
    final pharmacyId = await _pharmacyId();
    if (pharmacyId == null) return false;
    final res = await _repo.addItem(
      pharmacyId: pharmacyId,
      vendorProductId: vendorProductId,
      quantity: quantity,
    );
    final ok = res.isRight();
    if (ok) await load();
    return ok;
  }

  Future<void> remove(String cartItemId) async {
    await _repo.removeItem(cartItemId);
    await load();
  }

  Future<void> setQuantity(String cartItemId, int quantity) async {
    await _repo.updateQuantity(cartItemId, quantity);
    await load();
  }

  void clearLocal() => emit(const CartState.loaded([]));
}
