import '../models/cart_line.dart';

class CheckoutException implements Exception {
  const CheckoutException(this.message);
  final String message;
}

abstract interface class CheckoutRepository {
  Future<void> placeOrder(List<CartLine> lines);
}

class SimulatedCheckoutRepository implements CheckoutRepository {
  const SimulatedCheckoutRepository({required bool shouldFail})
    : _shouldFail = shouldFail;

  final bool _shouldFail;

  @override
  Future<void> placeOrder(List<CartLine> lines) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (_shouldFail) {
      throw const CheckoutException(
        'Your order could not be placed. Your cart is unchanged.',
      );
    }
  }
}
