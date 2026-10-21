import 'package:flutter/material.dart';

import 'menu_view.dart';

/// Menu and cart state are owned by the shared app scope, above both routes.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) => const MenuView();
}
