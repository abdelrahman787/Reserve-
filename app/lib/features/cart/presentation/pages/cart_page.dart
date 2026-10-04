import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../orders/data/orders_repository.dart';
import '../../data/cart_repository.dart';
import '../cubit/cart_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _promo = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
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
      (_) {
        _promo.clear();
        context.read<CartCubit>().load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accent,
            content: Text('order_success'.tr()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'currency'.tr();
    return Scaffold(
      appBar: AppBar(title: Text('cart'.tr())),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.status == CartStatus.loading ||
              state.status == CartStatus.initial) {
            return const AppLoader();
          }
          if (state.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'cart_empty'.tr(),
              subtitle: 'cart_empty_hint'.tr(),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _CartTile(line: state.items[i], currency: cur),
                ),
              ),
              _CheckoutBar(
                total: state.total,
                currency: cur,
                promo: _promo,
                placing: _placing,
                onCheckout: _placing ? null : _checkout,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.line, required this.currency});
  final CartLine line;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${line.unitPrice.toStringAsFixed(2)} $currency',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            _QtyStepper(
              quantity: line.quantity,
              onChanged: (q) => cubit.setQuantity(line.id, q),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                '${line.lineTotal.toStringAsFixed(2)} $currency',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(quantity - 1)),
          SizedBox(
            width: 28,
            child: Text('$quantity', textAlign: TextAlign.center),
          ),
          _btn(Icons.add, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.currency,
    required this.promo,
    required this.placing,
    required this.onCheckout,
  });

  final double total;
  final String currency;
  final TextEditingController promo;
  final bool placing;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: promo,
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
                  Text('${total.toStringAsFixed(2)} $currency',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onCheckout,
                child: placing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('checkout'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
