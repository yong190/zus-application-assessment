import 'catalog_api.dart';

/// Deliberate launch modes for review; never a fallback for failed live requests.
enum CatalogMode { live, fixture, empty, error, invalid }

class FixtureCatalogApi implements CatalogApi {
  FixtureCatalogApi(this._mode);

  final CatalogMode _mode;

  @override
  Future<List<Object?>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    switch (_mode) {
      case CatalogMode.error:
        throw const CatalogException(
          'Unable to connect. Check your connection and retry.',
        );
      case CatalogMode.empty:
        return [];
      case CatalogMode.invalid:
        return [
          <String, Object>{'id': 1},
        ];
      case CatalogMode.live:
        throw StateError('Live mode must use HttpCatalogApi.');
      case CatalogMode.fixture:
        return [
          {
            'id': 1,
            'title': 'Fresh apples',
            'description': 'A crisp, sweet everyday favourite. Sold as a pack.',
            'category': 'groceries',
            'price': 9.99,
            'stock': 3,
          },
          {
            'id': 2,
            'title': 'Ground coffee',
            'description': 'A smooth medium roast for your morning cup.',
            'category': 'groceries',
            'price': 24.50,
            'stock': 0,
          },
          {
            'id': 3,
            'title': 'Daily moisturiser',
            'description': 'A lightweight moisturiser for everyday use.',
            'category': 'skin-care',
            'price': 18.90,
            'stock': 5,
          },
          {
            'id': 4,
            'title': 'Gentle cleanser',
            'description': 'A simple, refreshing face wash.',
            'category': 'skin-care',
            'price': 12.00,
            'stock': 1,
          },
        ];
    }
  }
}
