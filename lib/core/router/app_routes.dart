/// Route names and paths used across the app.
///
/// Routes are nested under `/fridge` so that deep links build a sensible
/// back stack (e.g. `/fridge/recipes/menemen/cook` pops back to the recipe,
/// then to suggestions, then to the fridge).
abstract final class AppRoutes {
  static const login = 'login';
  static const fridge = 'fridge';
  static const shoppingList = 'shopping-list';
  static const addIngredients = 'add-ingredients';
  static const scanConfirmation = 'scan-confirmation';
  static const recipeSuggestions = 'recipe-suggestions';
  static const recipeDetail = 'recipe-detail';
  static const cookingMode = 'cooking-mode';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const allergies = 'allergies';

  static const loginPath = '/login';
  static const fridgePath = '/fridge';

  /// Path parameter holding a recipe id.
  static const recipeIdParam = 'recipeId';

  /// Query parameter telling Scan Confirmation which mock source was used.
  static const scanSourceParam = 'source';
}

/// Mock capture source for the Scan Confirmation screen.
enum ScanSource {
  photo,
  receipt;

  static ScanSource fromQuery(String? value) =>
      value == ScanSource.receipt.name ? ScanSource.receipt : ScanSource.photo;
}
