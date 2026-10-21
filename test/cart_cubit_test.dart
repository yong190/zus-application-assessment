import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_cubit.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_state.dart';
import 'package:zus_application_assessment/features/cart/data/checkout_repository.dart';
import 'package:zus_application_assessment/features/cart/models/cart_line.dart';
import 'package:zus_application_assessment/features/menu/models/product.dart';

const apple = Product(
  id: 1,
  name: 'Apple',
  description: 'An apple',
  category: 'groceries',
  priceSen: 999,
  stock: 3,
);
const unavailable = Product(
  id: 2,
  name: 'Coffee',
  description: 'Coffee',
  category: 'groceries',
  priceSen: 2450,
  stock: 0,
);

class ControlledCheckout implements CheckoutRepository {
  final requests = <List<CartLine>>[];
  final completions = <Completer<void>>[];

  @override
  Future<void> placeOrder(List<CartLine> lines) {
    requests.add(lines);
    final completion = Completer<void>();
    completions.add(completion);
    return completion.future;
  }
}

void main() {
  late ControlledCheckout repository;
  setUp(() => repository = ControlledCheckout());

  blocTest<CartCubit, CartState>(
    'enforces stock, exact totals, decrement-to-remove and removal',
    build: () => CartCubit(repository),
    act: (cubit) {
      cubit.increment(unavailable);
      for (var i = 0; i < 5; i++) {
        cubit.increment(apple);
      }
      cubit.decrement(apple.id);
      cubit.decrement(apple.id);
      cubit.decrement(apple.id);
      cubit.decrement(apple.id);
      cubit.increment(apple);
      cubit.remove(apple.id);
    },
    expect: () => [
      for (final quantity in [1, 2, 3, 2, 1, 0, 1, 0])
        isA<CartState>()
            .having((s) => s.itemCount, 'quantity', quantity)
            .having((s) => s.totalSen, 'total sen', quantity * 999),
    ],
  );

  test('empty submission is rejected independently of the UI', () async {
    final cubit = CartCubit(repository);
    cubit.submit();
    expect(repository.requests, isEmpty);
    await cubit.close();
  });

  test(
    'submission locks synchronously, freezes a snapshot and ignores duplicate taps',
    () async {
      final cubit = CartCubit(repository)..increment(apple);
      cubit.submit();
      for (var i = 0; i < 10; i++) {
        cubit.submit();
      }
      cubit.increment(apple);
      cubit.decrement(apple.id);
      cubit.remove(apple.id);
      cubit.dismissResult();
      expect(cubit.state.isSubmitting, isTrue);
      expect(cubit.state.itemCount, 1);
      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.single.quantity, 1);
      expect(() => repository.requests.single.clear(), throwsUnsupportedError);
      expect(() => cubit.state.lines.clear(), throwsUnsupportedError);
      repository.completions.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.checkoutStatus, CheckoutStatus.success);
      expect(cubit.state.lines, isEmpty);
      cubit.dismissResult();
      expect(cubit.state.checkoutStatus, CheckoutStatus.idle);
      await cubit.close();
    },
  );

  test('failure preserves contents and permits another attempt', () async {
    final cubit = CartCubit(repository)..increment(apple);
    cubit.submit();
    repository.completions.first.completeError(
      const CheckoutException('Try again'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.checkoutStatus, CheckoutStatus.failure);
    expect(cubit.state.totalSen, 999);
    cubit.submit();
    expect(repository.requests, hasLength(2));
    expect(cubit.state.checkoutError, isNull);
    repository.completions.last.complete();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.checkoutStatus, CheckoutStatus.success);
    await cubit.close();
  });

  test(
    'a late response after disposal does not emit into a closed Cubit',
    () async {
      final cubit = CartCubit(repository)..increment(apple);
      cubit.submit();
      await cubit.close();
      repository.completions.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.isClosed, isTrue);
    },
  );

  test('state snapshots do not expose a mutable caller-owned map', () {
    final lines = {1: const CartLine(product: apple, quantity: 1)};
    final state = CartState(lines: lines);
    lines.clear();
    expect(state.itemCount, 1);
    expect(() => state.lines.clear(), throwsUnsupportedError);
  });
}
