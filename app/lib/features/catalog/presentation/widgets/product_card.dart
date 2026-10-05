import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = product.lowestPrice;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: _Leading(url: product.imageUrl, theme: theme),
        title: Text(product.tradeName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.genericName != null)
              Text(product.genericName!,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (product.producer != null)
              Text(product.producer!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price != null ? '${price.toStringAsFixed(2)} ${'currency'.tr()}' : '—',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            Text(
              product.inStock ? 'in_stock'.tr() : 'out_of_stock'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: product.inStock ? Colors.green : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.url, required this.theme});
  final String? url;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: const Icon(Icons.medication),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 26,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.medication),
        ),
      ),
    );
  }
}
