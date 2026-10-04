part of 'catalog_cubit.dart';

enum CatalogStatus { initial, loading, loaded, error }

class CatalogState extends Equatable {
  const CatalogState._(
    this.status, {
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.message,
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
    String? selectedCategoryId,
  ) : this._(CatalogStatus.loaded,
            products: products,
            categories: categories,
            selectedCategoryId: selectedCategoryId);

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

  @override
  List<Object?> get props =>
      [status, products, categories, selectedCategoryId, message];
}
