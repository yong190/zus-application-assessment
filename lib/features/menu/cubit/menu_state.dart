import 'package:equatable/equatable.dart';

import '../models/product.dart';

enum MenuStatus { initial, loading, loaded, failure }

class MenuState extends Equatable {
  MenuState({
    this.status = MenuStatus.initial,
    List<MenuCategory> categories = const [],
    this.error,
  }) : categories = List.unmodifiable(categories);

  const MenuState.initial()
    : status = MenuStatus.initial,
      categories = const [],
      error = null;

  final MenuStatus status;
  final List<MenuCategory> categories;
  final String? error;

  MenuState copyWith({
    MenuStatus? status,
    List<MenuCategory>? categories,
    String? error,
  }) => MenuState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    error: error,
  );

  @override
  List<Object?> get props => [status, categories, error];
}
