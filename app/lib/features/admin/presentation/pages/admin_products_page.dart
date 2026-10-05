import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/admin_repository.dart';
import '../../data/models/vendor_product_row.dart';

typedef _PickedImage = ({Uint8List bytes, String ext});

Future<_PickedImage?> _pickImage() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1000,
    imageQuality: 80,
  );
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  final ext = x.name.contains('.') ? x.name.split('.').last.toLowerCase() : 'jpg';
  return (bytes: bytes, ext: ext);
}

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

  Future<void> _uploadImageFor(String productId) async {
    final picked = await _pickImage();
    if (picked == null) return;
    final res = await sl<AdminRepository>()
        .uploadProductImage(productId, picked.bytes, ext: picked.ext);
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.accent,
              content: Text('image_uploaded'.tr())),
        );
      },
    );
  }

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
            return const AppLoader();
          }
          if (_vendorId == null) {
            return EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'admin_no_vendor'.tr());
          }
          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'admin_no_products'.tr());
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
                  leading: _Thumb(url: r.imageUrl),
                  title: Text(r.tradeName),
                  subtitle: Text(
                      '${'price'.tr()}: ${r.price.toStringAsFixed(2)} ${'currency'.tr()}  ·  '
                      '${'admin_stock'.tr()}: ${r.stockQty}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'upload_image'.tr(),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        onPressed: () => _uploadImageFor(r.productId),
                      ),
                      Icon(
                        r.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: r.isAvailable ? Colors.green : Colors.grey,
                      ),
                    ],
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
    _PickedImage? picked;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('admin_add_product'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Thumb(bytes: picked?.bytes),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final p = await _pickImage();
                        if (p != null) setD(() => picked = p);
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text('pick_image'.tr()),
                    ),
                  ],
                ),
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
      ),
    );

    if (saved == true && trade.text.trim().isNotEmpty) {
      final repo = sl<AdminRepository>();
      final res = await repo.createProductWithOffer(
        vendorId: _vendorId!,
        tradeName: trade.text.trim(),
        genericName: generic.text.trim().isEmpty ? null : generic.text.trim(),
        producer: producer.text.trim().isEmpty ? null : producer.text.trim(),
        price: double.tryParse(price.text) ?? 0,
        stockQty: int.tryParse(stock.text) ?? 0,
      );
      if (!mounted) return;
      await res.fold(
        (f) async => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (productId) async {
          if (picked != null) {
            await repo.uploadProductImage(productId, picked!.bytes,
                ext: picked!.ext);
          }
          _refresh();
        },
      );
    }
    trade.dispose();
    generic.dispose();
    producer.dispose();
    price.dispose();
    stock.dispose();
  }
}

/// A small product thumbnail: network image, picked bytes, or a fallback icon.
class _Thumb extends StatelessWidget {
  const _Thumb({this.url, this.bytes});
  final String? url;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    Widget child;
    if (bytes != null) {
      child = Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(Icons.medication),
      );
    } else {
      child = Container(
        width: size,
        height: size,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.medication, color: AppColors.primary),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: child);
  }
}
