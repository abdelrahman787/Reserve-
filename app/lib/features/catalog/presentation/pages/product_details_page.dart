import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../cart/data/cart_repository.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/product.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<Product?> _future;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Product?> _load() async {
    final res = await sl<CatalogRepository>().fetchProduct(widget.productId);
    return res.fold((_) => null, (p) => p);
  }

  Future<void> _addToCart(Product product) async {
    final offer = product.bestOffer;
    if (offer?.vendorProductId == null) return;
    setState(() => _adding = true);
    final pharmacyId = await sl<SessionService>().pharmacyId();
    if (pharmacyId == null) {
      if (mounted) {
        setState(() => _adding = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('error'.tr())));
      }
      return;
    }
    final res = await sl<CartRepository>().addItem(
      pharmacyId: pharmacyId,
      vendorProductId: offer!.vendorProductId!,
    );
    if (!mounted) return;
    setState(() => _adding = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('added_to_cart'.tr()))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('details'.tr())),
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snap.data;
          if (product == null) {
            return Center(child: Text('no_results'.tr()));
          }
          final price = product.lowestPrice;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(product.tradeName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (product.genericName != null)
                _row('generic_name'.tr(), product.genericName!),
              if (product.producer != null)
                _row('producer'.tr(), product.producer!),
              if (product.pharmacology != null)
                _row('pharmacology'.tr(), product.pharmacology!),
              if (product.indications != null)
                _row('indications'.tr(), product.indications!),
              if (product.dosage != null) _row('dosage'.tr(), product.dosage!),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('price'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    price != null
                        ? '${price.toStringAsFixed(2)} ${'currency'.tr()}'
                        : '—',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    (!product.inStock || _adding) ? null : () => _addToCart(product),
                icon: _adding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart),
                label: Text(
                    product.inStock ? 'add_to_cart'.tr() : 'out_of_stock'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value),
        ],
      ),
    );
  }
}
