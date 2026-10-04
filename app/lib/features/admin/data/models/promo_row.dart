class PromoRow {
  PromoRow({
    required this.id,
    required this.code,
    required this.dType,
    required this.dValue,
    required this.minOrder,
    required this.isActive,
    this.description,
  });

  final String id;
  final String code;
  final String dType; // percent | fixed
  final double dValue;
  final double minOrder;
  final bool isActive;
  final String? description;

  factory PromoRow.fromMap(Map<String, dynamic> m) => PromoRow(
        id: m['id'] as String,
        code: m['code'] as String? ?? '',
        dType: m['d_type'] as String? ?? 'percent',
        dValue: (m['d_value'] as num?)?.toDouble() ?? 0,
        minOrder: (m['min_order'] as num?)?.toDouble() ?? 0,
        isActive: m['is_active'] as bool? ?? true,
        description: m['description'] as String?,
      );
}
