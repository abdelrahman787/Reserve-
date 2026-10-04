import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_status_chip.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text('orders'.tr())),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          switch (state.status) {
            case OrdersStatus.initial:
            case OrdersStatus.loading:
              return const AppLoader();
            case OrdersStatus.error:
              return EmptyState(
                icon: Icons.wifi_off_rounded,
                title: state.message ?? 'error'.tr(),
                actionLabel: 'retry'.tr(),
                onAction: () => context.read<OrdersCubit>().load(),
              );
            case OrdersStatus.loaded:
              if (state.orders.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'no_orders'.tr(),
                  subtitle: 'orders_coming_soon'.tr(),
                );
              }
              return RefreshIndicator(
                onRefresh: () => context.read<OrdersCubit>().load(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = state.orders[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/order/${o.id}'),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                o.vendorName ?? 'order'.tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            OrderStatusChip(status: o.status),
                          ],
                        ),
                        subtitle: Text(df.format(o.createdAt.toLocal())),
                        trailing: Text(
                          '${o.total.toStringAsFixed(2)} ${'currency'.tr()}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
