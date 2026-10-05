import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/order.dart';
import '../../data/orders_repository.dart';
import '../widgets/order_status_chip.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<PharmaOrder?> _future = _load();
  bool _paying = false;

  Future<PharmaOrder?> _load() => sl<OrdersRepository>()
      .fetchOrder(widget.orderId)
      .then((res) => res.fold((_) => null, (o) => o));

  Future<void> _payFromWallet() async {
    setState(() => _paying = true);
    final res = await sl<OrdersRepository>().payFromWallet(widget.orderId);
    if (!mounted) return;
    setState(() {
      _paying = false;
      if (res.isRight()) _future = _load();
    });
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.accent,
            content: Text('paid_success'.tr())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final cur = 'currency'.tr();
    return Scaffold(
      appBar: AppBar(title: Text('order'.tr())),
      body: FutureBuilder<PharmaOrder?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final o = snap.data;
          if (o == null) return Center(child: Text('no_results'.tr()));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(o.vendorName ?? 'order'.tr(),
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  OrderStatusChip(status: o.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(df.format(o.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 28),
              ...o.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(it.productName)),
                      Text('${it.quantity} × ${it.unitPrice.toStringAsFixed(2)}'),
                      const SizedBox(width: 12),
                      Text('${it.lineTotal.toStringAsFixed(2)} $cur'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),
              _summaryRow('subtotal'.tr(), '${o.subtotal.toStringAsFixed(2)} $cur'),
              if (o.discount > 0)
                _summaryRow(
                    'discount'.tr(), '-${o.discount.toStringAsFixed(2)} $cur'),
              _summaryRow(
                  'delivery_fee'.tr(),
                  o.deliveryFee > 0
                      ? '${o.deliveryFee.toStringAsFixed(2)} $cur'
                      : 'free'.tr()),
              const SizedBox(height: 4),
              _summaryRow('total'.tr(), '${o.total.toStringAsFixed(2)} $cur',
                  bold: true),
              if (o.note != null && o.note!.isNotEmpty) ...[
                const Divider(height: 28),
                Text('order_note'.tr(),
                    style: Theme.of(context).textTheme.labelMedium),
                Text(o.note!),
              ],
              if (o.status == 'pending') ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _paying ? null : _payFromWallet,
                  icon: _paying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.account_balance_wallet_outlined),
                  label: Text('pay_from_wallet'.tr()),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
