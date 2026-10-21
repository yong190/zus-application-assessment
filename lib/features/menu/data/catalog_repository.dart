import '../models/product.dart';
import 'catalog_api.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final CatalogApi _api;

  Future<List<MenuCategory>> fetchMenu() async {
    final rows = await _api.fetchProducts();
    final grouped = <String, List<Product>>{};
    final ids = <int>{};
    for (final row in rows) {
      if (row
          case {
            'id': final int id,
            'title': final String name,
            'description': final String description,
            'category': final String category,
            'price': final num price,
            'stock': final int stock,
          }
          when id > 0 &&
              name.trim().isNotEmpty &&
              description.trim().isNotEmpty &&
              category.trim().isNotEmpty &&
              price.isFinite &&
              price >= 0 &&
              stock >= 0 &&
              ids.add(id)) {
        final product = Product(
          id: id,
          name: name,
          description: description,
          category: category,
          // The source has no currency: numeric prices are assumed MYR.
          priceSen: (price * 100).round(),
          stock: stock,
        );
        (grouped[category] ??= []).add(product);
      } else {
        throw const CatalogException(
          'The menu contains invalid item data. Please retry.',
        );
      }
    }
    return List.unmodifiable([
      for (final entry in grouped.entries)
        MenuCategory(name: entry.key, products: entry.value),
    ]);
  }
}
