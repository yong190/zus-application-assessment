import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/checkout_notice.dart';
import '../../../shared/format_money.dart';
import '../../../shared/quantity_control.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../cubit/menu_cubit.dart';
import '../cubit/menu_state.dart';
import '../models/product.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SafeArea(child: CheckoutNotice()),
    appBar: AppBar(
      title: const Text('Menu'),
      actions: [
        BlocSelector<CartCubit, CartState, int>(
          selector: (state) => state.itemCount,
          builder: (context, count) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge.count(
              count: count,
              isLabelVisible: count > 0,
              child: IconButton(
                key: const ValueKey('open-cart'),
                tooltip: 'Open cart, $count items',
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            key: const PageStorageKey('menu-scroll'),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('Browse the selection and make it yours.'),
                ),
              ),
              BlocBuilder<MenuCubit, MenuState>(
                builder: (context, state) {
                  switch (state.status) {
                    case MenuStatus.initial:
                    case MenuStatus.loading:
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Loading menu',
                          ),
                        ),
                      );
                    case MenuStatus.failure:
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 40),
                              const SizedBox(height: 16),
                              Text(state.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.read<MenuCubit>().load(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    case MenuStatus.loaded:
                      if (state.categories.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('No items available.')),
                        );
                      }
                      return SliverMainAxisGroup(
                        slivers: [
                          for (final category in state.categories) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  8,
                                ),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    _categoryLabel(category.name),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                              ),
                            ),
                            SliverList.builder(
                              itemCount: category.products.length,
                              itemBuilder: (context, index) => _ProductCard(
                                key: ValueKey(category.products[index].id),
                                product: category.products[index],
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _categoryLabel(String category) => category
    .split('-')
    .map(
      (word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final available = product.stock > 0;
    final theme = Theme.of(context);
    return Card.outlined(
      color: available ? null : theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(product.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              formatMoney(product.priceSen),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  available
                      ? 'In stock · ${product.stock} available'
                      : 'Out of stock',
                  style: TextStyle(
                    color: available
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
                QuantityControl(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
