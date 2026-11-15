import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/auth_provider.dart';
import 'package:frigo/providers/favorites_provider.dart';
import 'package:frigo/providers/profile_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      routerProvider.overrideWithValue(
        createAppRouter(initialLocation: location),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FrigoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Login', () {
    testWidgets('shows validation errors for bad credentials', (tester) async {
      final container = await pumpAt(tester, '/login');

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-email')), 'nope');
      await tester.enterText(find.byKey(const Key('login-password')), '123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(container.read(authProvider), isNull);
      expect(find.text('Cook with what you already have.'), findsOneWidget);
    });

    testWidgets('valid email signs in and opens the fridge', (tester) async {
      final container = await pumpAt(tester, '/login');
      await tester.enterText(
        find.byKey(const Key('login-email')),
        ' Elif@Example.com ',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'secret123',
      );
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(container.read(authProvider), 'elif@example.com');
      expect(find.text('My Fridge'), findsOneWidget);
    });

    testWidgets('Google sign-in uses the seeded account', (tester) async {
      final container = await pumpAt(tester, '/login');
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(container.read(authProvider), 'elif@example.com');
      expect(find.text('My Fridge'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('shows user, live stats, tags and shopping count',
        (tester) async {
      await pumpAt(tester, '/fridge/profile');

      expect(find.text('EY'), findsOneWidget);
      expect(find.text('Elif Yılmaz'), findsOneWidget);
      expect(find.text('elif@example.com'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-favorites')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-meals-cooked')),
          matching: find.text('15'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-items-saved')),
          matching: find.text('23'),
        ),
        findsOneWidget,
      );
      expect(find.text('Peanuts'), findsOneWidget);
      expect(find.text('5 items'), findsOneWidget);
    });

    testWidgets('log out clears the session', (tester) async {
      final container = await pumpAt(tester, '/fridge/profile');
      container.read(authProvider.notifier).signInWithGoogle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(container.read(authProvider), isNull);
      expect(find.text('Log in'), findsOneWidget);
    });
  });

  group('Favorite recipes', () {
    testWidgets('grid shows Ready badges, cooked and missing counts',
        (tester) async {
      await pumpAt(tester, '/fridge/profile/favorites');

      expect(find.text('Menemen'), findsOneWidget);
      expect(find.text('Baked sea bass'), findsOneWidget);
      expect(find.text('Lentil soup'), findsOneWidget);
      expect(find.text('Rice pudding'), findsOneWidget);

      // Menemen and baked sea bass have everything in the fridge.
      expect(find.text('Ready'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('favorite-menemen')),
          matching: find.text('Ready'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cooked 6 times'), findsOneWidget);
      expect(find.text('Missing 1'), findsOneWidget); // red lentils
      expect(find.text('Missing 3'), findsOneWidget); // rice, sugar, cinnamon
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('search filters by title and ingredient', (tester) async {
      await pumpAt(tester, '/fridge/profile/favorites');

      await tester.enterText(find.byKey(const Key('favorites-search')), 'sea');
      await tester.pumpAndSettle();
      expect(find.text('Baked sea bass'), findsOneWidget);
      expect(find.text('Menemen'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('favorites-search')),
        'cinnamon',
      );
      await tester.pumpAndSettle();
      expect(find.text('Rice pudding'), findsOneWidget);
      expect(find.text('Baked sea bass'), findsNothing);

      await tester.enterText(find.byKey(const Key('favorites-search')), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('No favorites match "xyz".'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Menemen'), findsOneWidget);
    });

    testWidgets('heart removes a recipe from favorites', (tester) async {
      final container = await pumpAt(tester, '/fridge/profile/favorites');

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('favorite-rice-pudding')),
          matching: find.byTooltip('Remove from favorites'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rice pudding'), findsNothing);
      expect(container.read(profileProvider).isFavorite('rice-pudding'), false);
    });

    testWidgets('tapping a card opens the recipe detail', (tester) async {
      await pumpAt(tester, '/fridge/profile/favorites');
      await tester.tap(find.text('Menemen'));
      await tester.pumpAndSettle();
      expect(find.text('Start Cooking'), findsOneWidget);
    });
  });

  group('Allergies and diet', () {
    testWidgets('chips start from the saved profile', (tester) async {
      await pumpAt(tester, '/fridge/profile/allergies');

      final peanuts = tester.widget<FilterChip>(
        find.byKey(const Key('allergen-peanuts')),
      );
      final milk = tester.widget<FilterChip>(
        find.byKey(const Key('allergen-milk')),
      );
      final none = tester.widget<ChoiceChip>(
        find.byKey(const Key('diet-none')),
      );
      expect(peanuts.selected, isTrue);
      expect(milk.selected, isFalse);
      expect(none.selected, isTrue);
      expect(
        find.text('Recipes with these ingredients are hidden from your '
            'suggestions.'),
        findsOneWidget,
      );
    });

    testWidgets('save persists allergies, custom ingredient and diet',
        (tester) async {
      final container = await pumpAt(tester, '/fridge/profile');
      await tester.tap(find.text('Allergies and diet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('allergen-sesame')));
      await tester.enterText(
        find.byKey(const Key('custom-allergy-input')),
        'lactose',
      );
      await tester.tap(find.byTooltip('Add allergy'));
      await tester.pumpAndSettle();
      expect(find.text('Lactose'), findsOneWidget);

      // Duplicates and standard allergens are not added as custom chips.
      await tester.enterText(
        find.byKey(const Key('custom-allergy-input')),
        'LACTOSE',
      );
      await tester.tap(find.byTooltip('Add allergy'));
      await tester.enterText(
        find.byKey(const Key('custom-allergy-input')),
        'eggs',
      );
      await tester.tap(find.byTooltip('Add allergy'));
      await tester.pumpAndSettle();
      expect(find.text('Lactose'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('allergen-eggs')))
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('diet-vegetarian')));
      await tester.pumpAndSettle();
      expect(find.text('No meat, poultry, fish or seafood.'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final profile = container.read(profileProvider);
      expect(
        profile.allergies,
        {Allergen.peanuts, Allergen.sesame, Allergen.eggs},
      );
      expect(profile.customAllergies, ['Lactose']);
      expect(profile.diet, Diet.vegetarian);
      expect(container.read(profileRepositoryProvider).loadProfile(), profile);

      // Back on Profile with the new tags.
      expect(find.text('Allergies and diet saved'), findsOneWidget);
      expect(find.text('Lactose'), findsOneWidget);
      expect(find.text('Sesame'), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
    });

    testWidgets('custom chip can be removed and back discards edits',
        (tester) async {
      final container = await pumpAt(tester, '/fridge/profile');
      await tester.tap(find.text('Allergies and diet'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('custom-allergy-input')),
        'Kiwi',
      );
      await tester.tap(find.byTooltip('Add allergy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Kiwi'));
      await tester.pumpAndSettle();
      expect(find.text('Kiwi'), findsNothing);

      await tester.tap(find.byKey(const Key('allergen-fish')));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(container.read(profileProvider).allergies, {Allergen.peanuts});
    });
  });

  group('favorites search helpers', () {
    test('foldForSearch ignores case and Turkish diacritics', () {
      expect(foldForSearch('  Cacık  '), 'cacik');
      expect(foldForSearch('ŞÇĞÖÜ'), 'scgou');
    });

    test('filterFavorites returns everything for a blank query', () {
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => _today)],
      );
      addTearDown(container.dispose);
      final favorites = container.read(favoriteRecipesProvider);
      expect(filterFavorites(favorites, '   '), favorites);
      expect(
        filterFavorites(favorites, 'MENEMEN').map((f) => f.recipe.id),
        ['menemen'],
      );
    });
  });
}
