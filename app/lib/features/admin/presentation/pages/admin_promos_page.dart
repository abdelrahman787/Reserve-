import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../data/admin_repository.dart';
import '../../data/models/promo_row.dart';

class AdminPromosPage extends StatefulWidget {
  const AdminPromosPage({super.key});

  @override
  State<AdminPromosPage> createState() => _AdminPromosPageState();
}

class _AdminPromosPageState extends State<AdminPromosPage> {
  late Future<List<PromoRow>> _future;
  String? _vendorId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PromoRow>> _load() async {
    _vendorId = await sl<SessionService>().vendorId();
    if (_vendorId == null) return [];
    final res = await sl<AdminRepository>().fetchPromos(_vendorId!);
    return res.fold((_) => <PromoRow>[], (r) => r);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vendorId == null ? null : _openAddDialog,
        icon: const Icon(Icons.add),
        label: Text('admin_add_promo'.tr()),
      ),
      body: FutureBuilder<List<PromoRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_vendorId == null) {
            return Center(child: Text('admin_no_vendor'.tr()));
          }
          final promos = snap.data ?? [];
          if (promos.isEmpty) {
            return Center(child: Text('admin_no_promos'.tr()));
          }
          final cur = 'currency'.tr();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: promos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = promos[i];
              final value = p.dType == 'percent'
                  ? '${p.dValue.toStringAsFixed(0)}%'
                  : '${p.dValue.toStringAsFixed(2)} $cur';
              return SwitchListTile(
                title: Text(p.code,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '$value  ·  ${'admin_min_order'.tr()}: ${p.minOrder.toStringAsFixed(0)} $cur'),
                value: p.isActive,
                onChanged: (v) async {
                  await sl<AdminRepository>().setPromoActive(p.id, v);
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddDialog() async {
    final code = TextEditingController();
    final value = TextEditingController();
    final minOrder = TextEditingController(text: '0');
    String dType = 'percent';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('admin_add_promo'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'promo_code'.tr()),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'percent', label: Text('admin_percent'.tr())),
                  ButtonSegment(
                      value: 'fixed', label: Text('admin_fixed'.tr())),
                ],
                selected: {dType},
                onSelectionChanged: (s) => setD(() => dType = s.first),
              ),
              TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'admin_value'.tr()),
              ),
              TextField(
                controller: minOrder,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'admin_min_order'.tr()),
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

    if (saved == true && code.text.trim().isNotEmpty) {
      final res = await sl<AdminRepository>().createPromo(
        vendorId: _vendorId!,
        code: code.text.trim().toUpperCase(),
        dType: dType,
        dValue: double.tryParse(value.text) ?? 0,
        minOrder: double.tryParse(minOrder.text) ?? 0,
      );
      if (mounted) {
        res.fold(
          (f) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message))),
          (_) => _refresh(),
        );
      }
    }
    code.dispose();
    value.dispose();
    minOrder.dispose();
  }
}
