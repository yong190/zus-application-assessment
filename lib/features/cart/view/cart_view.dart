import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/checkout_notice.dart';
import '../../../shared/format_money.dart';
import '../../../shared/quantity_control.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../models/cart_line.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SafeArea(child: CheckoutNotice()),
    appBar: AppBar(
      title: const Text('Your cart'),
      leading: IconButton(
        tooltip: 'Back to menu',
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              BlocBuilder<CartCubit, CartState>(
                buildWhen: (previous, current) => !listEquals(
                  previous.lines.keys.toList(),
                  current.lines.keys.toList(),
                ),
                builder: (context, state) {
                  if (state.lines.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 56),
                            const SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Find something you like on the menu.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Browse menu'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final ids = state.lines.keys.toList(growable: false);
                  return SliverList.builder(
                    itemCount: ids.length,
                    itemBuilder: (context, index) => _CartRow(
                      key: ValueKey(ids[index]),
                      productId: ids[index],
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: _OrderSummary()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CartRow extends StatelessWidget {
  const _CartRow({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartCubit, CartState, (CartLine?, bool)>(
        selector: (state) => (state.lines[productId], state.isSubmitting),
        builder: (context, selection) {
          final (line, locked) = selection;
          if (line == null) return const SizedBox.shrink();
          return Card.outlined(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${formatMoney(line.product.priceSen)} each'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      QuantityControl(product: line.product),
                      TextButton.icon(
                        onPressed: locked
                            ? null
                            : () => context.read<CartCubit>().remove(productId),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Subtotal ${formatMoney(line.totalSen)}'),
                ],
              ),
            ),
          );
        },
      );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartCubit, CartState, (int, int, bool)>(
        selector: (state) =>
            (state.totalSen, state.itemCount, state.isSubmitting),
        builder: (context, selection) {
          final (total, count, submitting) = selection;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Total · $count ${count == 1 ? 'item' : 'items'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(total),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('place-order'),
                  onPressed: submitting || count == 0
                      ? null
                      : () => context.read<CartCubit>().submit(),
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(submitting ? 'Placing order…' : 'Place Order'),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
