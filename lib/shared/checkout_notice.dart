import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/cart/cubit/cart_cubit.dart';
import '../features/cart/cubit/cart_state.dart';

class CheckoutNotice extends StatelessWidget {
  const CheckoutNotice({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartCubit, CartState, (CheckoutStatus, String?)>(
        selector: (state) => (state.checkoutStatus, state.checkoutError),
        builder: (context, selection) {
          final (status, error) = selection;
          if (status == CheckoutStatus.idle) return const SizedBox.shrink();
          final colors = Theme.of(context).colorScheme;
          final message = switch (status) {
            CheckoutStatus.submitting =>
              'Placing your order… Cart changes are paused.',
            CheckoutStatus.success => 'Order placed. Thank you!',
            CheckoutStatus.failure =>
              error ?? 'Unable to place your order. Please retry.',
            CheckoutStatus.idle => '',
          };
          return Semantics(
            liveRegion: true,
            child: Card(
              color: status == CheckoutStatus.failure
                  ? colors.errorContainer
                  : colors.secondaryContainer,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: status == CheckoutStatus.submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              status == CheckoutStatus.success
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(message)),
                    if (status != CheckoutStatus.submitting)
                      IconButton(
                        tooltip: 'Dismiss order result',
                        onPressed: () =>
                            context.read<CartCubit>().dismissResult(),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
