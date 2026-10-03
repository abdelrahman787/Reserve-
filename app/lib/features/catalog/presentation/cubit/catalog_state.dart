part of 'catalog_cubit.dart';

enum CatalogStatus { initial, loading, loaded, error }

class CatalogState extends Equatable {
  const CatalogState._(this.status, {this.products = const [], this.message});

  const CatalogState.initial() : this._(CatalogStatus.initial);
  const CatalogState.loading() : this._(CatalogStatus.loading);
  const CatalogState.loaded(List<Product> products)
      : this._(CatalogStatus.loaded, products: products);
  const CatalogState.error(String message)
      : this._(CatalogStatus.error, message: message);

  final CatalogStatus status;
  final List<Product> products;
  final String? message;

  @override
  List<Object?> get props => [status, products, message];
}
