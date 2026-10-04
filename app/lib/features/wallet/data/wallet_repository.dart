import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';

class WalletSummary {
  WalletSummary({required this.balance, required this.currency});
  final double balance;
  final String currency;
}

class WalletTxn {
  WalletTxn({
    required this.amount,
    required this.type,
    required this.createdAt,
    this.reason,
  });

  final double amount;
  final String type; // credit | debit
  final DateTime createdAt;
  final String? reason;

  factory WalletTxn.fromMap(Map<String, dynamic> m) => WalletTxn(
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        type: m['txn_type'] as String? ?? 'credit',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
        reason: m['reason'] as String?,
      );
}

class WalletRepository {
  WalletRepository(this._client);
  final SupabaseClient _client;

  Future<Either<Failure, WalletSummary>> fetchWallet(String pharmacyId) async {
    try {
      final row = await _client
          .from('wallets')
          .select('balance, currency')
          .eq('pharmacy_id', pharmacyId)
          .maybeSingle();
      return Right(WalletSummary(
        balance: (row?['balance'] as num?)?.toDouble() ?? 0,
        currency: row?['currency'] as String? ?? 'EGP',
      ));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, List<WalletTxn>>> fetchTransactions(
      String pharmacyId) async {
    try {
      final rows = await _client
          .from('wallet_transactions')
          .select('amount, txn_type, reason, created_at, wallets!inner(pharmacy_id)')
          .eq('wallets.pharmacy_id', pharmacyId)
          .order('created_at', ascending: false)
          .limit(50);
      final txns = (rows as List)
          .map((e) => WalletTxn.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(txns);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
