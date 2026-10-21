import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_cubit.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_state.dart';
import 'package:zus_application_assessment/features/cart/models/cart_line.dart';
import 'package:zus_application_assessment/features/cart/view/cart_view.dart';
import 'package:zus_application_assessment/features/menu/cubit/menu_cubit.dart';
import 'package:zus_application_assessment/features/menu/cubit/menu_state.dart';
import 'package:zus_application_assessment/features/menu/models/product.dart';
import 'package:zus_application_assessment/features/menu/view/menu_view.dart';

class MockCartCubit extends MockCubit<CartState> implements CartCubit {}

class MockMenuCubit extends MockCubit<MenuState> implements MenuCubit {}

const apple = Product(
  id: 1,
  name: 'Apples',
  description: 'Fresh apples',
  category: 'groceries',
  priceSen: 999,
  stock: 3,
);
const coffee = Product(
  id: 2,
  name: 'Coffee',
  description: 'Ground coffee',
  category: 'groceries',
  priceSen: 2450,
  stock: 5,
);

void main() {
  late MockCartCubit cart;
  late StreamController<CartState> states;

  setUp(() {
    cart = MockCartCubit();
    states = StreamController<CartState>();
    whenListen(cart, states.stream, initialState: const CartState.initial());
  });

  tearDown(() async {
    await states.close();
    await cart.close();
  });

  testWidgets(
    'quantity update leaves unrelated menu controls and catalog intact',
    (tester) async {
      final menu = MockMenuCubit();
      whenListen(
        menu,
        const Stream<MenuState>.empty(),
        initialState: MenuState(
          status: MenuStatus.loaded,
          categories: [
            MenuCategory(name: 'groceries', products: [apple, coffee]),
          ],
        ),
      );
      addTearDown(menu.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<MenuCubit>.value(value: menu),
            BlocProvider<CartCubit>.value(value: cart),
          ],
          child: const MaterialApp(home: MenuView()),
        ),
      );
      final unrelated = find.byKey(const ValueKey('increment-2'));
      final originalControl = tester.widget(unrelated);
      final originalTitle = tester.widget(find.text('Apples'));
      states.add(
        CartState(lines: {1: const CartLine(product: apple, quantity: 2)}),
      );
      await tester.pump();
      expect(find.text('2'), findsWidgets);
      expect(find.byTooltip('Open cart, 2 items'), findsOneWidget);
      expect(tester.widget(unrelated), same(originalControl));
      expect(tester.widget(find.text('Apples')), same(originalTitle));

      states.add(
        cart.state.copyWith(checkoutStatus: CheckoutStatus.submitting),
      );
      await tester.pump();
      expect(tester.widget<IconButton>(unrelated).onPressed, isNull);
      expect(
        find.text('Placing your order… Cart changes are paused.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiple cart rows retain correct quantities and totals after removal',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider<CartCubit>.value(
          value: cart,
          child: const MaterialApp(home: CartView()),
        ),
      );
      states.add(
        CartState(
          lines: {
            1: const CartLine(product: apple, quantity: 2),
            2: const CartLine(product: coffee, quantity: 1),
          },
        ),
      );
      await tester.pump();
      expect(find.text('Subtotal RM19.98'), findsOneWidget);
      expect(find.text('Subtotal RM24.50'), findsOneWidget);
      expect(find.text('RM44.48'), findsOneWidget);

      states.add(
        CartState(lines: {2: const CartLine(product: coffee, quantity: 3)}),
      );
      await tester.pump();
      expect(find.text('Apples'), findsNothing);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Subtotal RM73.50'), findsOneWidget);
      expect(find.text('RM73.50'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
