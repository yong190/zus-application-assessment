import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zus_application_assessment/app.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_cubit.dart';
import 'package:zus_application_assessment/features/cart/cubit/cart_state.dart';
import 'package:zus_application_assessment/features/menu/data/fixture_catalog_api.dart';
import 'package:zus_application_assessment/features/menu/view/menu_view.dart';

Future<void> loadFixture(WidgetTester tester, {bool failure = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ZusAssessmentApp(
      catalogMode: CatalogMode.fixture,
      checkoutShouldFail: failure,
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shared quantities survive routing, theme, orientation and larger text',
    (tester) async {
      await loadFixture(tester);
      final add = find.byKey(const ValueKey('increment-1'));
      await tester.tap(add);
      await tester.pump();
      final cart = tester.element(find.byType(MenuView)).read<CartCubit>();
      expect(cart.state.itemCount, 1);
      final soldOut = tester.widget<IconButton>(
        find.byKey(const ValueKey('increment-2')),
      );
      expect(soldOut.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('open-cart')));
      await tester.pumpAndSettle();
      expect(find.text('Subtotal RM9.99'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('increment-1')));
      await tester.pump();
      expect(cart.state.totalSen, 1998);
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      tester.view.physicalSize = const Size(844, 390);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(cart.state.itemCount, 2);
      await tester.tap(find.byTooltip('Back to menu'));
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(MenuView)).read<CartCubit>(),
        same(cart),
      );
      expect(cart.state.itemCount, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'checkout survives leaving the cart and a background/resume cycle',
    (tester) async {
      await loadFixture(tester);
      final cart = tester.element(find.byType(MenuView)).read<CartCubit>();
      await tester.tap(find.byKey(const ValueKey('increment-1')));
      await tester.tap(find.byKey(const ValueKey('open-cart')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('place-order')));
      await tester.pump();
      expect(cart.state.isSubmitting, isTrue);
      await tester.tap(find.byTooltip('Back to menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Both routes can be painted during the pop animation; all controls lock.
      final addButtons = tester.widgetList<IconButton>(
        find.byKey(const ValueKey('increment-1')),
      );
      expect(addButtons, isNotEmpty);
      for (final button in addButtons) {
        expect(button.onPressed, isNull);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(cart.state.checkoutStatus, CheckoutStatus.success);
      expect(cart.state.lines, isEmpty);
      expect(find.textContaining('Order placed.'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss order result'));
      await tester.pump();
      expect(find.textContaining('Order placed.'), findsNothing);
    },
  );

  testWidgets('checkout failure keeps cart and enables retry', (tester) async {
    await loadFixture(tester, failure: true);
    await tester.tap(find.byKey(const ValueKey('increment-1')));
    await tester.tap(find.byKey(const ValueKey('open-cart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('place-order')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your order could not be placed.'),
      findsOneWidget,
    );
    expect(find.text('Subtotal RM9.99'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('place-order')))
          .onPressed,
      isNotNull,
    );
  });

  for (final mode in [
    CatalogMode.empty,
    CatalogMode.error,
    CatalogMode.invalid,
  ]) {
    testWidgets('menu ${mode.name} has an explicit state', (tester) async {
      await tester.pumpWidget(ZusAssessmentApp(catalogMode: mode));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      if (mode == CatalogMode.empty) {
        expect(find.text('No items available.'), findsOneWidget);
      } else {
        expect(find.text('Retry'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsOneWidget);
      }
    });
  }
}
