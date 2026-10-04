import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/product.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Future<Product?> _future = sl<CatalogRepository>()
      .fetchProduct(widget.productId)
      .then((res) => res.fold((_) => null, (p) => p));

  int _qty = 1;
  bool _adding = false;

  Future<void> _addToCart(Product product) async {
    final offer = product.bestOffer;
    if (offer?.vendorProductId == null) return;
    setState(() => _adding = true);
    final ok = await sl<CartCubit>().add(offer!.vendorProductId!, quantity: _qty);
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.accent : null,
        content: Text(ok ? 'added_to_cart'.tr() : 'error'.tr()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'currency'.tr();
    return Scaffold(
      appBar: AppBar(title: Text('details'.tr())),
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          final product = snap.data;
          if (product == null) {
            return EmptyState(
                icon: Icons.inventory_2_outlined, title: 'no_results'.tr());
          }
          final price = product.lowestPrice;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(product.tradeName,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (product.requiresRx) const _RxBadge(),
                ],
              ),
              const SizedBox(height: 12),
              if (product.genericName != null)
                _row('generic_name'.tr(), product.genericName!),
              if (product.producer != null)
                _row('producer'.tr(), product.producer!),
              if (product.pharmacology != null)
                _row('pharmacology'.tr(), product.pharmacology!),
              if (product.indications != null)
                _row('indications'.tr(), product.indications!),
              if (product.dosage != null) _row('dosage'.tr(), product.dosage!),
              if (product.offers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'offers_count'.tr(args: ['${product.offers.length}']),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('price'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    price != null ? '${price.toStringAsFixed(2)} $cur' : '—',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snap) {
          final product = snap.data;
          if (product == null) return const SizedBox.shrink();
          final enabled = product.inStock && !_adding;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (product.inStock) ...[
                    _QtyStepper(
                      quantity: _qty,
                      onChanged: (q) =>
                          setState(() => _qty = q.clamp(1, 999)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: enabled ? () => _addToCart(product) : null,
                      icon: _adding
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(product.inStock
                          ? 'add_to_cart'.tr()
                          : 'out_of_stock'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 12)),
            Text(value),
          ],
        ),
      );
}

class _RxBadge extends StatelessWidget {
  const _RxBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('requires_rx'.tr(),
          style: const TextStyle(
              color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => onChanged(quantity - 1),
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}
