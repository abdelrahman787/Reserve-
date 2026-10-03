import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'admin_orders_page.dart';
import 'admin_products_page.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_dashboard'.tr()),
          bottom: TabBar(
            tabs: [
              Tab(text: 'admin_products'.tr()),
              Tab(text: 'admin_orders'.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AdminProductsPage(), AdminOrdersPage()],
        ),
      ),
    );
  }
}
