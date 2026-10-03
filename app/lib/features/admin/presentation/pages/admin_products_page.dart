import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../data/admin_repository.dart';
import '../../data/models/vendor_product_row.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  late Future<List<VendorProductRow>> _future;
  String? _vendorId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<VendorProductRow>> _load() async {
    _vendorId = await sl<SessionService>().vendorId();
    if (_vendorId == null) return [];
    final res = await sl<AdminRepository>().fetchVendorProducts(_vendorId!);
    return res.fold((_) => <VendorProductRow>[], (r) => r);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vendorId == null ? null : _openAddDialog,
        icon: const Icon(Icons.add),
        label: Text('admin_add_product'.tr()),
      ),
      body: FutureBuilder<List<VendorProductRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_vendorId == null) {
            return Center(child: Text('admin_no_vendor'.tr()));
          }
          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return Center(child: Text('admin_no_products'.tr()));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rows[i];
                return ListTile(
                  title: Text(r.tradeName),
                  subtitle: Text(
                      '${'price'.tr()}: ${r.price.toStringAsFixed(2)} ${'currency'.tr()}  ·  '
                      '${'admin_stock'.tr()}: ${r.stockQty}'),
                  trailing: Icon(
                    r.isAvailable ? Icons.check_circle : Icons.cancel,
                    color: r.isAvailable ? Colors.green : Colors.grey,
                  ),
                  onTap: () => _openEditDialog(r),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(VendorProductRow r) async {
    final price = TextEditingController(text: r.price.toStringAsFixed(2));
    final discount =
        TextEditingController(text: r.discountPercent.toStringAsFixed(0));
    final stock = TextEditingController(text: r.stockQty.toString());
    bool available = r.isAvailable;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(r.tradeName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'price'.tr()),
              ),
              TextField(
                controller: discount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'admin_discount_pct'.tr()),
              ),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'admin_stock'.tr()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('admin_available'.tr()),
                value: available,
                onChanged: (v) => setD(() => available = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr())),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('save'.tr())),
          ],
        ),
      ),
    );

    if (saved == true) {
      await sl<AdminRepository>().updateVendorProduct(
        r.id,
        price: double.tryParse(price.text),
        discountPercent: double.tryParse(discount.text),
        stockQty: int.tryParse(stock.text),
        isAvailable: available,
      );
      _refresh();
    }
    price.dispose();
    discount.dispose();
    stock.dispose();
  }

  Future<void> _openAddDialog() async {
    final trade = TextEditingController();
    final generic = TextEditingController();
    final producer = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin_add_product'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: trade,
                  decoration:
                      InputDecoration(labelText: 'admin_trade_name'.tr())),
              TextField(
                  controller: generic,
                  decoration: InputDecoration(labelText: 'generic_name'.tr())),
              TextField(
                  controller: producer,
                  decoration: InputDecoration(labelText: 'producer'.tr())),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'price'.tr())),
              TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'admin_stock'.tr())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('save'.tr())),
        ],
      ),
    );

    if (saved == true && trade.text.trim().isNotEmpty) {
      final res = await sl<AdminRepository>().createProductWithOffer(
        vendorId: _vendorId!,
        tradeName: trade.text.trim(),
        genericName: generic.text.trim().isEmpty ? null : generic.text.trim(),
        producer: producer.text.trim().isEmpty ? null : producer.text.trim(),
        price: double.tryParse(price.text) ?? 0,
        stockQty: int.tryParse(stock.text) ?? 0,
      );
      if (mounted) {
        res.fold(
          (f) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message))),
          (_) => _refresh(),
        );
      }
    }
    trade.dispose();
    generic.dispose();
    producer.dispose();
    price.dispose();
    stock.dispose();
  }
}
