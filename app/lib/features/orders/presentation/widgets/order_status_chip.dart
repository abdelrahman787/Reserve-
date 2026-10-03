import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final String status;

  Color _color(BuildContext context) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      case 'out_for_delivery':
      case 'processing':
      case 'confirmed':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'order_status_$status'.tr(),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
