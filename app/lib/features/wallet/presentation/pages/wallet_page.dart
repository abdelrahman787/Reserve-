import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/wallet_repository.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<(WalletSummary, List<WalletTxn>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(WalletSummary, List<WalletTxn>)> _load() async {
    final pharmacyId = await sl<SessionService>().pharmacyId();
    if (pharmacyId == null) {
      return (WalletSummary(balance: 0, currency: 'EGP'), <WalletTxn>[]);
    }
    final repo = sl<WalletRepository>();
    final w = await repo.fetchWallet(pharmacyId);
    final t = await repo.fetchTransactions(pharmacyId);
    return (
      w.fold((_) => WalletSummary(balance: 0, currency: 'EGP'), (s) => s),
      t.fold((_) => <WalletTxn>[], (list) => list),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text('wallet'.tr())),
      body: FutureBuilder<(WalletSummary, List<WalletTxn>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (wallet, txns) = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(balance: wallet.balance, currency: wallet.currency),
              const SizedBox(height: 20),
              Text('wallet_transactions'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (txns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('wallet_no_transactions'.tr())),
                )
              else
                ...txns.map((t) {
                  final credit = t.type == 'credit';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: (credit ? AppColors.accent : AppColors.danger)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        credit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: credit ? AppColors.accent : AppColors.danger,
                      ),
                    ),
                    title: Text(t.reason ?? (credit ? 'credit'.tr() : 'debit'.tr())),
                    subtitle: Text(df.format(t.createdAt.toLocal())),
                    trailing: Text(
                      '${credit ? '+' : '-'}${t.amount.toStringAsFixed(2)} ${wallet.currency}',
                      style: TextStyle(
                        color: credit ? AppColors.accent : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.currency});
  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('wallet_balance'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(2)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
