import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../orders/presentation/widgets/order_status_chip.dart';

const _statuses = [
  'pending',
  'confirmed',
  'processing',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<PharmaOrder>> _future;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) sl<SupabaseClient>().removeChannel(channel);
    super.dispose();
  }

  void _subscribeRealtime() {
    _channel = sl<SupabaseClient>()
        .channel('public:orders:admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            if (mounted) _refresh();
          },
        )
        .subscribe();
  }

  Future<List<PharmaOrder>> _load() async {
    final res = await sl<OrdersRepository>().fetchOrders();
    return res.fold((_) => <PharmaOrder>[], (o) => o);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _changeStatus(PharmaOrder o) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses
              .map((s) => ListTile(
                    title: Text('order_status_$s'.tr()),
                    trailing: o.status == s ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, s),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null && picked != o.status) {
      final res = await sl<OrdersRepository>().updateStatus(o.id, picked);
      if (!mounted) return;
      res.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (_) => _refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'currency'.tr();
    return FutureBuilder<List<PharmaOrder>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return Center(child: Text('admin_no_orders'.tr()));
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final o = orders[i];
              return Card(
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${o.id.substring(0, 8)}'),
                      OrderStatusChip(status: o.status),
                    ],
                  ),
                  subtitle: Text('${o.total.toStringAsFixed(2)} $cur'),
                  trailing: TextButton(
                    onPressed: () => _changeStatus(o),
                    child: Text('admin_update_status'.tr()),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
