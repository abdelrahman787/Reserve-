import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.id, required this.nameEn, required this.nameAr});

  final String id;
  final String nameEn;
  final String nameAr;

  String name(bool isArabic) => isArabic ? nameAr : nameEn;

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        nameEn: m['name_en'] as String? ?? '',
        nameAr: m['name_ar'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id];
}
