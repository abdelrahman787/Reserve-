import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';

/// Thin wrapper over Supabase auth, exposing a Failure-typed API.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  /// Emits the current user (or null) on every auth change.
  Stream<User?> get authChanges =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user);

  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) return const Left(AuthFailure('Login failed'));
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Registers a pharmacy account: creates the auth user, a pharmacy row, and
  /// links them via the profile (profile row itself is created by a DB trigger).
  Future<Either<Failure, User>> registerPharmacy({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String pharmacyName,
    String? licenseNumber,
    String? address,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      final user = res.user;
      if (user == null) return const Left(AuthFailure('Registration failed'));

      // Create the pharmacy and link it to the profile.
      final pharmacy = await _client
          .from('pharmacies')
          .insert({
            'name': pharmacyName,
            'license_number': licenseNumber,
            'phone': phone,
            'email': email,
            'address': address,
          })
          .select('id')
          .single();

      await _client
          .from('profiles')
          .update({'pharmacy_id': pharmacy['id'], 'role': 'pharmacy'}).eq(
              'id', user.id);

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
