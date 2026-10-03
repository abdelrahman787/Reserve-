import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app_name'.tr())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => context.read<CatalogCubit>().search(v),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {}, // TODO: filter sheet
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                switch (state.status) {
                  case CatalogStatus.loading:
                  case CatalogStatus.initial:
                    return const Center(child: CircularProgressIndicator());
                  case CatalogStatus.error:
                    return _Message(
                      text: state.message ?? 'error'.tr(),
                      onRetry: () => context.read<CatalogCubit>().load(),
                    );
                  case CatalogStatus.loaded:
                    if (state.products.isEmpty) {
                      return _Message(text: 'no_results'.tr());
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

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text('retry'.tr())),
        ],
      ),
    );
  }
}
