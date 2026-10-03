import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('orders'.tr())),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            Text('orders_coming_soon'.tr()),
          ],
        ),
      ),
    );
  }
}
