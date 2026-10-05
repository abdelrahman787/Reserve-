import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
// Hide Supabase's AuthState: this library defines its own AuthState below.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../data/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState.unknown()) {
    _sub = _repo.authChanges.listen((user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<User?> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());
    final res = await _repo.signIn(email: email, password: password);
    res.fold(
      (f) => emit(AuthState.error(f.message)),
      (u) => emit(AuthState.authenticated(u)),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String pharmacyName,
    String? licenseNumber,
    String? address,
  }) async {
    emit(const AuthState.loading());
    final res = await _repo.registerPharmacy(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      pharmacyName: pharmacyName,
      licenseNumber: licenseNumber,
      address: address,
    );
    res.fold(
      (f) => emit(AuthState.error(f.message)),
      (u) => emit(AuthState.authenticated(u)),
    );
  }

  Future<void> logout() => _repo.signOut();
}
