// End-to-end widget tests for Frigo's core loop:
// add an ingredient -> see it on the fridge shelf -> check the updated
// recipe match % -> send missing ingredients to the shopping list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/fridge_provider.dart';
import 'package:frigo/providers/recipe_suggestions_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';
import 'package:frigo/providers/shopping_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  String location = '/login',
}) async {
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(Key('recipe-card-$id'));

Finder _onCard(String id, String text) =>
    find.descendant(of: _card(id), matching: find.text(text));

Finder _onShelf(ShelfCategory shelf, String text) => find.descendant(
      of: find.byKey(Key('shelf-${shelf.name}')),
      matching: find.text(text),
    );

Finder _onNote(String noteId, String text) => find.descendant(
      of: find.byKey(Key('note-$noteId')),
      matching: find.text(text),
    );

/// Scrolls the recipe list until [finder] is built and visible.
Future<void> _scrollRecipesTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byKey(const Key('recipe-list')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

int _percentOf(ProviderContainer c, String recipeId) =>
    c.read(recipeInsightProvider(recipeId))!.match.matchPercent;

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
}

void main() {
  group('Core user loop', () {
    testWidgets(
        'manual add: login -> add garlic -> shelf -> match % rises -> '
        'missing pasta lands on the shopping list', (tester) async {
      final c = await _pumpApp(tester);

      // 1. Log in and land on the fridge.
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'you@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'secret123',
      );
      await _tap(tester, find.text('Log in'));
      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('13 items'), findsOneWidget);
      expect(
        _onShelf(ShelfCategory.vegetableDrawer, 'Garlic'),
        findsNothing,
      );

      // 2. Baseline recipe matches before adding anything.
      await _tap(tester, find.text('Suggest recipes'));
      expect(find.text('What to cook'), findsOneWidget);
      expect(_onCard('chicken-saute', '80% match – missing garlic'),
          findsOneWidget);
      await _scrollRecipesTo(tester, _card('pasta-with-yogurt'));
      expect(
        _onCard('pasta-with-yogurt', '40% match – missing pasta, garlic +1'),
        findsOneWidget,
      );
      expect(_percentOf(c, 'chicken-saute'), 80);
      expect(_percentOf(c, 'pasta-with-yogurt'), 40);
      await _back(tester);

      // 3. Add garlic through the manual entry form.
      await _tap(tester, find.text('+ Add ingredients'));
      expect(find.text('OR TYPE IT IN'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ingredient-input')),
        'garl',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('suggestion-Garlic')));
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('shelf-choice-vegetableDrawer')),
            )
            .selected,
        isTrue,
      );
      await _tap(tester, find.byKey(const Key('add-to-fridge')));

      // 4. The new item sits on the vegetable drawer shelf.
      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('14 items'), findsOneWidget);
      expect(
        _onShelf(ShelfCategory.vegetableDrawer, 'Garlic'),
        findsOneWidget,
      );
      expect(
        c.read(fridgeProvider).where((i) => i.name == 'Garlic').single.shelf,
        ShelfCategory.vegetableDrawer,
      );

      // Let the "Garlic added" snack bar time out so it cannot cover the
      // recipe card actions.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      // 5. Recipe matches reflect the new ingredient.
      await _tap(tester, find.text('Suggest recipes'));
      expect(_percentOf(c, 'chicken-saute'), 100);
      expect(_percentOf(c, 'pasta-with-yogurt'), 60);
      await _scrollRecipesTo(tester, _card('chicken-saute'));
      expect(_onCard('chicken-saute', '100% match'), findsOneWidget);
      expect(
        find.byKey(const Key('add-missing-chicken-saute')),
        findsNothing,
      );

      // 6. Send the still-missing pasta to the shopping list. Dried mint is
      //    already on the cacık note, so only pasta is offered.
      final addMissing = find.byKey(const Key('add-missing-pasta-with-yogurt'));
      await _scrollRecipesTo(tester, addMissing);
      expect(
        _onCard(
          'pasta-with-yogurt',
          '60% match – missing pasta and dried mint',
        ),
        findsOneWidget,
      );
      expect(
        _onCard('pasta-with-yogurt', 'Add pasta to shopping list'),
        findsOneWidget,
      );
      await tester.tap(addMissing);
      await tester.pump();
      expect(find.text('Pasta added to your shopping list'), findsOneWidget);
      expect(
        _onCard('pasta-with-yogurt', 'On your shopping list'),
        findsOneWidget,
      );

      final note = c
          .read(shoppingNotesProvider)
          .singleWhere((n) => n.recipeId == 'pasta-with-yogurt');
      expect(note.title, 'For pasta with yogurt');
      expect(note.color, NoteColor.yellow);
      expect(note.items.map((i) => i.name), ['Pasta']);
      expect(c.read(shoppingOpenItemCountProvider), 6);

      // 7. The note shows up on the fridge door, then back to the fridge.
      await tester.pumpAndSettle();
      await _tap(tester, find.text('View'));
      expect(find.text('Notes on your fridge door'), findsOneWidget);
      expect(_onNote(note.id, 'For pasta with yogurt'), findsOneWidget);
      expect(_onNote(note.id, 'Pasta'), findsOneWidget);

      await _tap(tester, find.byKey(const Key('open-fridge')));
      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('14 items'), findsOneWidget);
    });

    testWidgets(
        'photo scan: saved items fill shelves and lift the cacık match; '
        'remaining gaps point to the shopping list', (tester) async {
      final c = await _pumpApp(tester, location: '/fridge');
      expect(_percentOf(c, 'cacik'), 25);

      await _tap(tester, find.text('+ Add ingredients'));
      await _tap(tester, find.text('Take a photo'));
      expect(find.text('Check what we found'), findsOneWidget);
      expect(find.text('Save 4 to my fridge'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('scan-save')));

      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('17 items'), findsOneWidget);
      for (final name in ['Cucumber', 'Spinach', 'Garlic']) {
        expect(
          _onShelf(ShelfCategory.vegetableDrawer, name),
          findsOneWidget,
        );
      }
      expect(_onShelf(ShelfCategory.dairy, 'Feta cheese'), findsOneWidget);

      await _tap(tester, find.text('Suggest recipes'));
      expect(_percentOf(c, 'cacik'), 75);
      final cacikMissing = find.byKey(const Key('add-missing-cacik'));
      await _scrollRecipesTo(tester, cacikMissing);
      expect(
        _onCard('cacik', '75% match – missing dried mint'),
        findsOneWidget,
      );
      // Dried mint is already on the cacık note, so nothing new is added.
      final notesBefore = c.read(shoppingNotesProvider);
      expect(_onCard('cacik', 'On your shopping list'), findsOneWidget);

      await _tap(tester, cacikMissing);
      expect(find.text('Notes on your fridge door'), findsOneWidget);
      expect(_onNote('note-cacik', 'Dried mint'), findsOneWidget);
      expect(c.read(shoppingNotesProvider), notesBefore);
    });

    testWidgets('completing a recipe lifts it to 100% and up the ranking',
        (tester) async {
      final c = await _pumpApp(tester, location: '/fridge/add');
      List<String> ranked() => [
            for (final m in c.read(filteredRecipeMatchesProvider)) m.recipe.id,
          ];
      final rankBefore = ranked().indexOf('lentil-soup');
      expect(_percentOf(c, 'lentil-soup'), 80);

      await tester.enterText(
        find.byKey(const Key('ingredient-input')),
        'Red lentils',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('add-to-fridge')));
      expect(find.text('14 items'), findsOneWidget);
      expect(
        c.read(fridgeProvider).where((i) => i.name == 'Red lentils'),
        hasLength(1),
      );

      await _tap(tester, find.text('Suggest recipes'));
      expect(_percentOf(c, 'lentil-soup'), 100);
      final soup = _card('lentil-soup');
      await _scrollRecipesTo(tester, soup);
      expect(_onCard('lentil-soup', '100% match'), findsOneWidget);
      expect(find.byKey(const Key('add-missing-lentil-soup')), findsNothing);

      expect(ranked().indexOf('lentil-soup'), lessThan(rankBefore));
    });
  });
}
