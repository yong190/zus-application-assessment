import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zus_application_assessment/features/menu/cubit/menu_cubit.dart';
import 'package:zus_application_assessment/features/menu/cubit/menu_state.dart';
import 'package:zus_application_assessment/features/menu/data/catalog_api.dart';
import 'package:zus_application_assessment/features/menu/data/catalog_repository.dart';

const validRow = <String, Object>{
  'id': 1,
  'title': 'Apple',
  'description': 'An apple',
  'category': 'groceries',
  'price': 9.99,
  'stock': 3,
};

class ControlledCatalog implements CatalogApi {
  final requests = <Completer<List<Object?>>>[];
  @override
  Future<List<Object?>> fetchProducts() {
    final request = Completer<List<Object?>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  late ControlledCatalog api;
  setUp(() => api = ControlledCatalog());

  blocTest<MenuCubit, MenuState>(
    'loading guard, failure, retry, grouping and cache',
    build: () => MenuCubit(CatalogRepository(api)),
    act: (cubit) async {
      cubit.load();
      cubit.load();
      expect(api.requests, hasLength(1));
      api.requests.first.completeError(const CatalogException('Offline'));
      await Future<void>.delayed(Duration.zero);
      cubit.load();
      api.requests.last.complete([validRow]);
      await Future<void>.delayed(Duration.zero);
      cubit.load();
      expect(api.requests, hasLength(2));
    },
    expect: () => [
      isA<MenuState>().having((s) => s.status, 'status', MenuStatus.loading),
      isA<MenuState>().having((s) => s.error, 'error', 'Offline'),
      isA<MenuState>().having((s) => s.status, 'status', MenuStatus.loading),
      isA<MenuState>().having(
        (s) => s.categories.single.products.single.priceSen,
        'sen',
        999,
      ),
    ],
  );

  test('a late menu response after disposal is ignored', () async {
    final cubit = MenuCubit(CatalogRepository(api))..load();
    await cubit.close();
    api.requests.single.complete([validRow]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isClosed, isTrue);
  });

  for (final rows in <List<Object?>>[
    [
      {'id': 1},
    ],
    [validRow, validRow],
    [
      {...validRow, 'price': -1},
    ],
    [
      {...validRow, 'stock': -1},
    ],
  ]) {
    test('invalid required data fails explicitly: $rows', () async {
      final result = CatalogRepository(api).fetchMenu();
      api.requests.single.complete(rows);
      await expectLater(result, throwsA(isA<CatalogException>()));
    });
  }

  test('valid empty catalog stays empty', () async {
    final result = CatalogRepository(api).fetchMenu();
    api.requests.single.complete([]);
    expect(await result, isEmpty);
  });
}
