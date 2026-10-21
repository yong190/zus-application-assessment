import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
}

abstract interface class CatalogApi {
  Future<List<Object?>> fetchProducts();
}

class HttpCatalogApi implements CatalogApi {
  HttpCatalogApi(this._client);

  final http.Client _client;

  @override
  Future<List<Object?>> fetchProducts() async {
    try {
      final response = await _client
          .get(
            Uri.https('dummyjson.com', '/products', {
              'limit': '0',
              'select': 'id,title,description,category,price,stock',
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const CatalogException(
          'The menu is unavailable. Please try again.',
        );
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['products'] is! List) {
        throw const FormatException('Expected products list');
      }
      return decoded['products'] as List<Object?>;
    } on TimeoutException {
      throw const CatalogException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const CatalogException(
        'Unable to connect. Check your connection and retry.',
      );
    } on FormatException {
      throw const CatalogException(
        'The menu data could not be read. Please retry.',
      );
    }
  }
}
