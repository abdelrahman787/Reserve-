import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';

part 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repo) : super(const CatalogState.initial());
  final CatalogRepository _repo;

  String _search = '';
  String? _categoryId;
  double? _minPrice;
  double? _maxPrice;
  List<Category> _categories = const [];

  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  Future<void> load() async {
    emit(CatalogState.loading(_categories, _categoryId));

    if (_categories.isEmpty) {
      final cats = await _repo.fetchCategories();
      cats.fold((_) {}, (list) => _categories = list);
    }

    final res = await _repo.fetchProducts(search: _search, categoryId: _categoryId);
    res.fold(
      (f) => emit(CatalogState.error(f.message, _categories, _categoryId)),
      (items) {
        final filtered = items.where((p) {
          final lp = p.lowestPrice;
          if (_minPrice != null && (lp == null || lp < _minPrice!)) return false;
          if (_maxPrice != null && (lp == null || lp > _maxPrice!)) return false;
          return true;
        }).toList();
        emit(CatalogState.loaded(filtered, _categories, _categoryId));
      },
    );
  }

  Future<void> search(String term) {
    _search = term;
    return load();
  }

  Future<void> selectCategory(String? categoryId) {
    _categoryId = categoryId;
    return load();
  }

  Future<void> setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    return load();
  }

  bool get hasPriceFilter => _minPrice != null || _maxPrice != null;
}
