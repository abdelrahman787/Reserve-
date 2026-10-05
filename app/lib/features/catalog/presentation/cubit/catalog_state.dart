part of 'catalog_cubit.dart';

enum CatalogStatus { initial, loading, loaded, error }

class CatalogState extends Equatable {
  const CatalogState._(
    this.status, {
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.message,
    this.hasMore = false,
    this.loadingMore = false,
  });

  const CatalogState.initial() : this._(CatalogStatus.initial);

  const CatalogState.loading(
    List<Category> categories,
    String? selectedCategoryId,
  ) : this._(CatalogStatus.loading,
            categories: categories, selectedCategoryId: selectedCategoryId);

  const CatalogState.loaded(
    List<Product> products,
    List<Category> categories,
    String? selectedCategoryId, {
    bool hasMore = false,
    bool loadingMore = false,
  }) : this._(CatalogStatus.loaded,
            products: products,
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            hasMore: hasMore,
            loadingMore: loadingMore);

  const CatalogState.error(
    String message,
    List<Category> categories,
    String? selectedCategoryId,
  ) : this._(CatalogStatus.error,
            message: message,
            categories: categories,
            selectedCategoryId: selectedCategoryId);

  final CatalogStatus status;
  final List<Product> products;
  final List<Category> categories;
  final String? selectedCategoryId;
  final String? message;
  final bool hasMore;
  final bool loadingMore;

  CatalogState copyWithLoadingMore(bool value) => CatalogState._(
        status,
        products: products,
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        message: message,
        hasMore: hasMore,
        loadingMore: value,
      );

  @override
  List<Object?> get props =>
      [status, products, categories, selectedCategoryId, message, hasMore, loadingMore];
}
