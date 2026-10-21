import 'package:bloc/bloc.dart';

import '../data/catalog_api.dart';
import '../data/catalog_repository.dart';
import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit(this._repository) : super(const MenuState.initial());

  final CatalogRepository _repository;

  void load() async {
    if (isClosed ||
        state.status == MenuStatus.loading ||
        state.status == MenuStatus.loaded)
      return;
    emit(state.copyWith(status: MenuStatus.loading));
    try {
      final categories = await _repository.fetchMenu();
      if (isClosed) return;
      emit(state.copyWith(status: MenuStatus.loaded, categories: categories));
    } on CatalogException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: MenuStatus.failure, error: error.message));
    }
  }
}
