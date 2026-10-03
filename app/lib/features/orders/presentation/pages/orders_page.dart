import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              return const Center(child: CircularProgressIndicator());
            case OrdersStatus.error:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? 'error'.tr()),
                    TextButton(
                      onPressed: () => context.read<OrdersCubit>().load(),
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              );
            case OrdersStatus.loaded:
              if (state.orders.isEmpty) {
                return Center(child: Text('no_orders'.tr()));
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
