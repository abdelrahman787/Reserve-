import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/product.dart';

part 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repo) : super(const CatalogState.initial());
  final CatalogRepository _repo;

  String _search = '';
  String? _categoryId;

  Future<void> load({String? search, String? categoryId, bool reset = true}) async {
    _search = search ?? _search;
    _categoryId = categoryId ?? _categoryId;
    emit(const CatalogState.loading());
    final res = await _repo.fetchProducts(search: _search, categoryId: _categoryId);
    res.fold(
      (f) => emit(CatalogState.error(f.message)),
      (items) => emit(CatalogState.loaded(items)),
    );
  }

  Future<void> search(String term) => load(search: term);
}
