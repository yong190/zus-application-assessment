import 'package:equatable/equatable.dart';

import '../models/cart_line.dart';

enum CheckoutStatus { idle, submitting, success, failure }

class CartState extends Equatable {
  CartState({
    Map<int, CartLine> lines = const {},
    this.checkoutStatus = CheckoutStatus.idle,
    this.checkoutError,
  }) : lines = Map.unmodifiable(lines);

  const CartState.initial()
    : lines = const {},
      checkoutStatus = CheckoutStatus.idle,
      checkoutError = null;

  final Map<int, CartLine> lines;
  final CheckoutStatus checkoutStatus;
  final String? checkoutError;

  bool get isSubmitting => checkoutStatus == CheckoutStatus.submitting;
  int get itemCount => lines.values.fold(0, (sum, line) => sum + line.quantity);
  int get totalSen => lines.values.fold(0, (sum, line) => sum + line.totalSen);

  CartState copyWith({
    Map<int, CartLine>? lines,
    CheckoutStatus? checkoutStatus,
    String? checkoutError,
  }) => CartState(
    lines: lines ?? this.lines,
    checkoutStatus: checkoutStatus ?? this.checkoutStatus,
    checkoutError: checkoutError,
  );

  @override
  List<Object?> get props => [lines, checkoutStatus, checkoutError];
}
