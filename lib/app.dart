import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'features/cart/cubit/cart_cubit.dart';
import 'features/cart/data/checkout_repository.dart';
import 'features/cart/view/cart_page.dart';
import 'features/menu/cubit/menu_cubit.dart';
import 'features/menu/data/catalog_api.dart';
import 'features/menu/data/catalog_repository.dart';
import 'features/menu/data/fixture_catalog_api.dart';
import 'features/menu/view/menu_page.dart';

class ZusAssessmentApp extends StatefulWidget {
  const ZusAssessmentApp({
    super.key,
    this.catalogMode = CatalogMode.live,
    this.checkoutShouldFail = false,
  });

  final CatalogMode catalogMode;
  final bool checkoutShouldFail;

  @override
  State<ZusAssessmentApp> createState() => _ZusAssessmentAppState();
}

class _ZusAssessmentAppState extends State<ZusAssessmentApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MenuPage(),
        routes: [
          GoRoute(path: 'cart', builder: (context, state) => const CartPage()),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<http.Client>(
        create: (_) => http.Client(),
        dispose: (client) => client.close(),
      ),
      RepositoryProvider<CatalogRepository>(
        create: (context) => CatalogRepository(
          widget.catalogMode == CatalogMode.live
              ? HttpCatalogApi(context.read<http.Client>())
              : FixtureCatalogApi(widget.catalogMode),
        ),
      ),
      RepositoryProvider<CheckoutRepository>(
        create: (_) =>
            SimulatedCheckoutRepository(shouldFail: widget.checkoutShouldFail),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MenuCubit(context.read<CatalogRepository>())..load(),
        ),
        BlocProvider(
          create: (context) => CartCubit(context.read<CheckoutRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'ZUS Application – Assessment',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF276453)),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF276453),
            brightness: Brightness.dark,
          ),
        ),
        routerConfig: _router,
      ),
    ),
  );
}
