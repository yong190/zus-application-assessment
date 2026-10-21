import 'package:flutter/material.dart';

import 'app.dart';
import 'features/menu/data/fixture_catalog_api.dart';

void main() {
  const mode = String.fromEnvironment('CATALOG_MODE', defaultValue: 'live');
  const checkoutShouldFail = bool.fromEnvironment('CHECKOUT_FAIL');
  runApp(
    ZusAssessmentApp(
      catalogMode: CatalogMode.values.byName(mode),
      checkoutShouldFail: checkoutShouldFail,
    ),
  );
}
