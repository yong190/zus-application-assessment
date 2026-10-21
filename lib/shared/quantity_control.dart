import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/cart/cubit/cart_cubit.dart';
import '../features/cart/cubit/cart_state.dart';
import '../features/menu/models/product.dart';

class QuantityControl extends StatelessWidget {
  const QuantityControl({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartCubit, CartState, (int, bool)>(
        selector: (state) =>
            (state.lines[product.id]?.quantity ?? 0, state.isSubmitting),
        builder: (context, selection) {
          final (quantity, locked) = selection;
          return Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.outlined(
                key: ValueKey('decrement-${product.id}'),
                tooltip: 'Decrease ${product.name}',
                onPressed: locked || quantity == 0
                    ? null
                    : () => context.read<CartCubit>().decrement(product.id),
                icon: const Icon(Icons.remove),
              ),
              Semantics(
                label: '${product.name}, $quantity in cart',
                child: SizedBox(
                  width: 40,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton.filledTonal(
                key: ValueKey('increment-${product.id}'),
                tooltip: quantity >= product.stock
                    ? 'Stock limit reached for ${product.name}'
                    : 'Add ${product.name}',
                onPressed: locked || quantity >= product.stock
                    ? null
                    : () => context.read<CartCubit>().increment(product),
                icon: const Icon(Icons.add),
              ),
            ],
          );
        },
      );
}
