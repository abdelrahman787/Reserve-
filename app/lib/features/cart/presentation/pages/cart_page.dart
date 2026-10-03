import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../orders/data/orders_repository.dart';
import '../../data/cart_repository.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartLine>> _future;
  final _promo = TextEditingController();
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<List<CartLine>> _load() async {
    final pharmacyId = await sl<SessionService>().pharmacyId();
    if (pharmacyId == null) return [];
    final res = await sl<CartRepository>().fetchItems(pharmacyId);
    return res.fold((_) => <CartLine>[], (items) => items);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _remove(String id) async {
    await sl<CartRepository>().removeItem(id);
    _refresh();
  }

  Future<void> _checkout() async {
    setState(() => _placing = true);
    final res = await sl<OrdersRepository>().checkout(
      promoCode: _promo.text.trim().isEmpty ? null : _promo.text.trim(),
    );
    if (!mounted) return;
    setState(() => _placing = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (ids) {
        _promo.clear();
        _refresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('order_success'.tr())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cart'.tr())),
      body: FutureBuilder<List<CartLine>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(child: Text('cart_empty'.tr()));
          }
          final total =
              items.fold<double>(0, (sum, e) => sum + e.lineTotal);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final line = items[i];
                    return ListTile(
                      title: Text(line.productName),
                      subtitle: Text(
                          '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} ${'currency'.tr()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              '${line.lineTotal.toStringAsFixed(2)} ${'currency'.tr()}'),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(line.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _promo,
                        decoration: InputDecoration(
                          labelText: 'promo_code'.tr(),
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('total'.tr(),
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${total.toStringAsFixed(2)} ${'currency'.tr()}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _placing ? null : _checkout,
                        child: _placing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('checkout'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
