import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/ingredient_catalog.dart';
import '../data/services/recipe_matcher.dart';

/// Stateless recipe ranking / allergy engine.
final recipeMatcherProvider = Provider<RecipeMatcher>(
  (ref) => const RecipeMatcher(),
);

/// Ingredient dictionary for autocomplete, shelves and expiry estimates.
final ingredientCatalogProvider = Provider<IngredientCatalog>(
  (ref) => const IngredientCatalog(),
);

/// Photo / receipt scanner (mock until a Vision OCR backend is added).
final ingredientScannerProvider = Provider<MockIngredientScanner>(
  (ref) => const MockIngredientScanner(),
);
