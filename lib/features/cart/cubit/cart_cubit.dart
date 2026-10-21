import 'package:bloc/bloc.dart';

import '../../menu/models/product.dart';
import '../data/checkout_repository.dart';
import '../models/cart_line.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._checkoutRepository) : super(const CartState.initial());

  final CheckoutRepository _checkoutRepository;

  void increment(Product product) {
    if (isClosed || state.isSubmitting) return;
    final existing = state.lines[product.id];
    final item = existing?.product ?? product;
    final quantity = existing?.quantity ?? 0;
    if (quantity >= item.stock) return;
    emit(
      state.copyWith(
        lines: {
          ...state.lines,
          item.id: CartLine(product: item, quantity: quantity + 1),
        },
        checkoutError: state.checkoutError,
      ),
    );
  }

  void decrement(int productId) {
    if (isClosed || state.isSubmitting) return;
    final line = state.lines[productId];
    if (line == null) return;
    if (line.quantity == 1) {
      remove(productId);
      return;
    }
    emit(
      state.copyWith(
        lines: {
          ...state.lines,
          productId: CartLine(
            product: line.product,
            quantity: line.quantity - 1,
          ),
        },
        checkoutError: state.checkoutError,
      ),
    );
  }

  void remove(int productId) {
    if (isClosed || state.isSubmitting || !state.lines.containsKey(productId))
      return;
    final lines = Map<int, CartLine>.of(state.lines)..remove(productId);
    emit(state.copyWith(lines: lines, checkoutError: state.checkoutError));
  }

  void submit() async {
    if (isClosed || state.isSubmitting || state.lines.isEmpty) return;
    final snapshot = List<CartLine>.unmodifiable(state.lines.values);
    // Synchronous transition: the next tap sees the guard before any await.
    emit(state.copyWith(checkoutStatus: CheckoutStatus.submitting));
    try {
      await _checkoutRepository.placeOrder(snapshot);
      if (isClosed) return;
      emit(state.copyWith(lines: {}, checkoutStatus: CheckoutStatus.success));
    } on CheckoutException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: error.message,
        ),
      );
    }
  }

  void dismissResult() {
    if (isClosed || state.isSubmitting) return;
    emit(state.copyWith(checkoutStatus: CheckoutStatus.idle));
  }
}
