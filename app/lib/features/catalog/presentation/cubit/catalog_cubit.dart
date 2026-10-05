import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';

part 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repo) : super(const CatalogState.initial());
  final CatalogRepository _repo;

  static const _pageSize = 30;

  String _search = '';
  String? _categoryId;
  double? _minPrice;
  double? _maxPrice;
  List<Category> _categories = const [];
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get hasPriceFilter => _minPrice != null || _maxPrice != null;

  List<Product> _applyPriceFilter(List<Product> items) => items.where((p) {
        final lp = p.lowestPrice;
        if (_minPrice != null && (lp == null || lp < _minPrice!)) return false;
        if (_maxPrice != null && (lp == null || lp > _maxPrice!)) return false;
        return true;
      }).toList();

  Future<void> load() async {
    emit(CatalogState.loading(_categories, _categoryId));
    _offset = 0;
    _hasMore = true;

    if (_categories.isEmpty) {
      final cats = await _repo.fetchCategories();
      cats.fold((_) {}, (list) => _categories = list);
    }

    final res = await _repo.fetchProducts(
        search: _search, categoryId: _categoryId, limit: _pageSize, offset: 0);
    res.fold(
      (f) => emit(CatalogState.error(f.message, _categories, _categoryId)),
      (items) {
        _hasMore = items.length == _pageSize;
        _offset = items.length;
        emit(CatalogState.loaded(
          _applyPriceFilter(items),
          _categories,
          _categoryId,
          hasMore: _hasMore,
        ));
      },
    );
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.status != CatalogStatus.loaded) {
      return;
    }
    _loadingMore = true;
    emit(state.copyWithLoadingMore(true));

    final res = await _repo.fetchProducts(
        search: _search,
        categoryId: _categoryId,
        limit: _pageSize,
        offset: _offset);
    final more = res.fold(
      (_) => <Product>[],
      (items) {
        _hasMore = items.length == _pageSize;
        _offset += items.length;
        return _applyPriceFilter(items);
      },
    );
    _loadingMore = false;
    emit(CatalogState.loaded(
      [...state.products, ...more],
      _categories,
      _categoryId,
      hasMore: _hasMore,
    ));
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
}
