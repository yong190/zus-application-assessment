import 'package:equatable/equatable.dart';

import '../../menu/models/product.dart';

class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;
  int get totalSen => product.priceSen * quantity;

  @override
  List<Object> get props => [product, quantity];
}
