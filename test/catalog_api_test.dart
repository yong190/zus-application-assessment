import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zus_application_assessment/features/menu/data/catalog_api.dart';
import 'package:zus_application_assessment/features/menu/data/catalog_repository.dart';

void main() {
  test(
    'HTTP request selects the full catalog and maps money and numeric stock',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'dummyjson.com');
        expect(request.url.path, '/products');
        expect(request.url.queryParameters['limit'], '0');
        return http.Response('''{"products":[{"id":1,"title":"Coffee",
        "description":"Ground coffee","category":"groceries","price":24.5,
        "stock":0,"availabilityStatus":"In Stock"}]}''', 200);
      });
      addTearDown(client.close);
      final menu = await CatalogRepository(HttpCatalogApi(client)).fetchMenu();
      expect(menu.single.products.single.priceSen, 2450);
      expect(menu.single.products.single.stock, 0);
    },
  );

  for (final response in [
    http.Response('Unavailable', 503),
    http.Response('not json', 200),
    http.Response('{"products":{}}', 200),
  ]) {
    test(
      'unusable server response becomes a user-facing failure: ${response.statusCode}/${response.body}',
      () async {
        final client = MockClient((_) async => response);
        addTearDown(client.close);
        await expectLater(
          HttpCatalogApi(client).fetchProducts(),
          throwsA(isA<CatalogException>()),
        );
      },
    );
  }

  test('transport failure becomes a readable connection error', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Connection refused'),
    );
    addTearDown(client.close);
    await expectLater(
      HttpCatalogApi(client).fetchProducts(),
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'message',
          contains('connection'),
        ),
      ),
    );
  });

  test('timeout becomes a readable retryable error', () async {
    final client = MockClient((_) async => throw TimeoutException('Timed out'));
    addTearDown(client.close);
    await expectLater(
      HttpCatalogApi(client).fetchProducts(),
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
