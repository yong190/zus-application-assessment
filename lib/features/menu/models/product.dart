import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priceSen,
    required this.stock,
  });

  final int id;
  final String name;
  final String description;
  final String category;
  final int priceSen;
  final int stock;

  @override
  List<Object> get props => [id, name, description, category, priceSen, stock];
}

class MenuCategory extends Equatable {
  MenuCategory({required this.name, required List<Product> products})
    : products = List.unmodifiable(products);

  final String name;
  final List<Product> products;

  @override
  List<Object> get props => [name, products];
}
