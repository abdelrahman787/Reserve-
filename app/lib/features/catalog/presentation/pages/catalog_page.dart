import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilter() async {
    final cubit = context.read<CatalogCubit>();
    final minC = TextEditingController(
        text: cubit.minPrice != null ? cubit.minPrice!.toStringAsFixed(0) : '');
    final maxC = TextEditingController(
        text: cubit.maxPrice != null ? cubit.maxPrice!.toStringAsFixed(0) : '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('filter_price'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'price_from'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'price_to'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      cubit.setPriceRange(null, null);
                      Navigator.pop(ctx);
                    },
                    child: Text('clear'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      cubit.setPriceRange(
                        double.tryParse(minC.text),
                        double.tryParse(maxC.text),
                      );
                      Navigator.pop(ctx);
                    },
                    child: Text('apply'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text('app_name'.tr())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => context.read<CatalogCubit>().search(v),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: BlocBuilder<CatalogCubit, CatalogState>(
                  builder: (context, _) {
                    final active = context.read<CatalogCubit>().hasPriceFilter;
                    return IconButton(
                      tooltip: 'filter'.tr(),
                      icon: Icon(Icons.tune,
                          color: active ? AppColors.primary : null),
                      onPressed: _openFilter,
                    );
                  },
                ),
              ),
            ),
          ),
          _CategoryChips(isArabic: isArabic),
          Expanded(
            child: BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                switch (state.status) {
                  case CatalogStatus.loading:
                  case CatalogStatus.initial:
                    return const _CatalogSkeleton();
                  case CatalogStatus.error:
                    return EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: state.message ?? 'error'.tr(),
                      actionLabel: 'retry'.tr(),
                      onAction: () => context.read<CatalogCubit>().load(),
                    );
                  case CatalogStatus.loaded:
                    if (state.products.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'no_results'.tr(),
                        subtitle: 'no_results_hint'.tr(),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<CatalogCubit>().load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.products.length,
                        itemBuilder: (_, i) {
                          final p = state.products[i];
                          return ProductCard(
                            product: p,
                            onTap: () => context.push('/product/${p.id}'),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        if (state.categories.isEmpty) return const SizedBox.shrink();
        final cubit = context.read<CatalogCubit>();
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip(context, 'all'.tr(), state.selectedCategoryId == null,
                  () => cubit.selectCategory(null)),
              ...state.categories.map((c) => _chip(
                    context,
                    c.name(isArabic),
                    state.selectedCategoryId == c.id,
                    () => cubit.selectCategory(c.id),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 7,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            ShimmerBox(width: 52, height: 52, radius: 26),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBox(width: 60, height: 16),
          ],
        ),
      ),
    );
  }
}
