import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/service_locator.dart';
import '../cart/presentation/pages/cart_page.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/presentation/cubit/catalog_cubit.dart';
import '../catalog/presentation/pages/catalog_page.dart';
import '../more/presentation/pages/more_page.dart';
import '../orders/data/orders_repository.dart';
import '../orders/presentation/cubit/orders_cubit.dart';
import '../orders/presentation/pages/orders_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      BlocProvider(
        create: (_) => CatalogCubit(sl<CatalogRepository>())..load(),
        child: const CatalogPage(),
      ),
      const CartPage(),
      BlocProvider(
        create: (_) =>
            OrdersCubit(sl<OrdersRepository>(), sl<SupabaseClient>())..load(),
        child: const OrdersPage(),
      ),
      const MorePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'home'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'cart'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'orders'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              label: 'more'.tr()),
        ],
      ),
    );
  }
}
