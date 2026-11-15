import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_ingredients/add_ingredients_screen.dart';
import '../../features/add_ingredients/scan_confirmation_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/cooking/cooking_mode_screen.dart';
import '../../features/fridge/fridge_screen.dart';
import '../../features/profile/allergies_screen.dart';
import '../../features/profile/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/recipes/recipe_detail_screen.dart';
import '../../features/recipes/recipe_suggestions_screen.dart';
import '../../features/shopping_list/shopping_list_screen.dart';
import '../widgets/not_found_screen.dart';
import 'app_routes.dart';

/// Creates the app-wide [GoRouter].
GoRouter createAppRouter({String initialLocation = AppRoutes.loginPath}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => NotFoundScreen(location: state.uri.path),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.loginPath),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.fridgePath,
        name: AppRoutes.fridge,
        builder: (context, state) => const FridgeScreen(),
        routes: [
          GoRoute(
            path: 'shopping-list',
            name: AppRoutes.shoppingList,
            builder: (context, state) => const ShoppingListScreen(),
          ),
          GoRoute(
            path: 'add',
            name: AppRoutes.addIngredients,
            builder: (context, state) => const AddIngredientsScreen(),
            routes: [
              GoRoute(
                path: 'scan',
                name: AppRoutes.scanConfirmation,
                builder: (context, state) => ScanConfirmationScreen(
                  source: ScanSource.fromQuery(
                    state.uri.queryParameters[AppRoutes.scanSourceParam],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'recipes',
            name: AppRoutes.recipeSuggestions,
            builder: (context, state) => const RecipeSuggestionsScreen(),
            routes: [
              GoRoute(
                path: ':${AppRoutes.recipeIdParam}',
                name: AppRoutes.recipeDetail,
                builder: (context, state) => RecipeDetailScreen(
                  recipeId: state.pathParameters[AppRoutes.recipeIdParam]!,
                ),
                routes: [
                  GoRoute(
                    path: 'cook',
                    name: AppRoutes.cookingMode,
                    builder: (context, state) => CookingModeScreen(
                      recipeId: state.pathParameters[AppRoutes.recipeIdParam]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'favorites',
                name: AppRoutes.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
              GoRoute(
                path: 'allergies',
                name: AppRoutes.allergies,
                builder: (context, state) => const AllergiesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Convenience navigation helpers so screens don't hand-build paths.
extension FrigoNavigation on BuildContext {
  void goToLogin() => goNamed(AppRoutes.login);
  void goToFridge() => goNamed(AppRoutes.fridge);
  void pushShoppingList() => pushNamed(AppRoutes.shoppingList);
  void pushAddIngredients() => pushNamed(AppRoutes.addIngredients);
  void pushScanConfirmation(ScanSource source) => pushNamed(
        AppRoutes.scanConfirmation,
        queryParameters: {AppRoutes.scanSourceParam: source.name},
      );
  void pushRecipeSuggestions() => pushNamed(AppRoutes.recipeSuggestions);
  void goToRecipeSuggestions() => goNamed(AppRoutes.recipeSuggestions);
  void pushRecipeDetail(String recipeId) => pushNamed(
        AppRoutes.recipeDetail,
        pathParameters: {AppRoutes.recipeIdParam: recipeId},
      );
  void pushCookingMode(String recipeId) => pushNamed(
        AppRoutes.cookingMode,
        pathParameters: {AppRoutes.recipeIdParam: recipeId},
      );
  void pushProfile() => pushNamed(AppRoutes.profile);
  void pushFavorites() => pushNamed(AppRoutes.favorites);
  void pushAllergies() => pushNamed(AppRoutes.allergies);
}
