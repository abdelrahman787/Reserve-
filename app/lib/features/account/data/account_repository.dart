import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';

class PharmacyProfile {
  PharmacyProfile({
    required this.id,
    required this.name,
    this.licenseNumber,
    this.phone,
    this.email,
    this.address,
  });

  final String id;
  final String name;
  final String? licenseNumber;
  final String? phone;
  final String? email;
  final String? address;

  factory PharmacyProfile.fromMap(Map<String, dynamic> m) => PharmacyProfile(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        licenseNumber: m['license_number'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
      );
}

class AccountRepository {
  AccountRepository(this._client);
  final SupabaseClient _client;

  Future<Either<Failure, PharmacyProfile>> fetchPharmacy(
      String pharmacyId) async {
    try {
      final row = await _client
          .from('pharmacies')
          .select('id, name, license_number, phone, email, address')
          .eq('id', pharmacyId)
          .single();
      return Right(PharmacyProfile.fromMap(row));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> updatePharmacy({
    required String pharmacyId,
    required String name,
    String? licenseNumber,
    String? phone,
    String? address,
  }) async {
    try {
      await _client.from('pharmacies').update({
        'name': name,
        'license_number': licenseNumber,
        'phone': phone,
        'address': address,
      }).eq('id', pharmacyId);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
