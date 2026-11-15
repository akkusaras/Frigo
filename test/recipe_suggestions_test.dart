import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/data/seed/seed_data.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/profile_provider.dart';
import 'package:frigo/providers/recipe_suggestions_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';
import 'package:frigo/providers/shopping_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

ProviderContainer _container({List<Override> extra = const []}) {
  final c = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => _today), ...extra],
  );
  addTearDown(c.dispose);
  return c;
}

Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final container = _container(
    extra: [
      routerProvider.overrideWithValue(
        createAppRouter(initialLocation: location),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FrigoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

List<String> _ids(ProviderContainer c) => [
  for (final m in c.read(filteredRecipeMatchesProvider)) m.recipe.id,
];

Finder _card(String id) => find.byKey(Key('recipe-card-$id'));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
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

void main() {
  group('recipe filters', () {
    test('seed suggestions are ranked by match and expiry', () {
      final c = _container();
      expect(_ids(c), [
        'baked-sea-bass',
        'menemen',
        'chicken-saute',
        'lentil-soup',
        'pasta-with-yogurt',
        'cacik',
        'rice-pudding',
      ]);
      expect(
        c.read(recipeSuggestionsProvider).hiddenAllergySummary,
        'Hidden: 2 recipes with peanuts (your allergy)',
      );
    });

    test('each chip narrows the list and chips combine', () {
      final c = _container();
      final filters = c.read(recipeFiltersProvider.notifier);

      filters.toggle(RecipeFilter.under20Min);
      expect(_ids(c), ['menemen', 'pasta-with-yogurt', 'cacik']);

      filters.toggle(RecipeFilter.under20Min);
      filters.toggle(RecipeFilter.vegetarian);
      expect(_ids(c), [
        'menemen',
        'lentil-soup',
        'pasta-with-yogurt',
        'cacik',
        'rice-pudding',
      ]);

      filters.toggle(RecipeFilter.vegetarian);
      filters.toggle(RecipeFilter.usesExpiring);
      expect(_ids(c), ['baked-sea-bass', 'pasta-with-yogurt', 'cacik']);

      filters.toggle(RecipeFilter.under20Min);
      expect(_ids(c), ['pasta-with-yogurt', 'cacik']);

      filters.clear();
      expect(c.read(recipeFiltersProvider), {RecipeFilter.allergySafe});
      expect(_ids(c), hasLength(7));
    });

    test('Allergy-safe cannot be switched off', () {
      final c = _container();
      c.read(recipeFiltersProvider.notifier).toggle(RecipeFilter.allergySafe);
      expect(c.read(recipeFiltersProvider), contains(RecipeFilter.allergySafe));
      expect(_ids(c), isNot(contains('chicken-satay')));
    });

    test('diet changes hide recipes and add a diet footer', () {
      final c = _container();
      final p = c.read(profileProvider);
      c.read(profileProvider.notifier).updateDietary(
        allergies: p.allergies,
        customAllergies: p.customAllergies,
        diet: Diet.vegetarian,
      );
      expect(_ids(c), isNot(contains('baked-sea-bass')));
      expect(
        c.read(recipeSuggestionsProvider).hiddenDietSummary,
        'Hidden: 2 recipes that are not vegetarian',
      );
    });

    test('recipe insight reports allergy triggers for hidden recipes', () {
      final c = _container();
      final satay = c.read(recipeInsightProvider('chicken-satay'))!;
      expect(satay.isAllergySafe, isFalse);
      expect(satay.allergyTriggers, {'peanuts'});
      final soup = c.read(recipeInsightProvider('lentil-soup'))!;
      expect(soup.isAllergySafe, isTrue);
      expect(soup.match.missingNames, ['Red lentils']);
      expect(c.read(recipeInsightProvider('nope')), isNull);
    });
  });

  group('shopping list from recipes', () {
    Recipe recipe(String id) =>
        SeedData.recipes.firstWhere((r) => r.id == id);

    test('creates a yellow note for the recipe', () {
      final c = _container();
      final added = c
          .read(shoppingNotesProvider.notifier)
          .addMissingForRecipe(recipe('rice-pudding'), [
            'Rice',
            'Sugar',
            'Cinnamon',
          ]);
      expect(added, 3);
      final note = c.read(shoppingNotesProvider).first;
      expect(note.title, 'For rice pudding');
      expect(note.color, NoteColor.yellow);
      expect(note.recipeId, 'rice-pudding');
      expect(note.items.map((i) => i.name), ['Rice', 'Sugar', 'Cinnamon']);
      expect(
        c.read(shoppingRepositoryProvider).loadNotes(),
        c.read(shoppingNotesProvider),
      );
    });

    test('skips open duplicates, reopens checked ones, is idempotent', () {
      final c = _container();
      final notifier = c.read(shoppingNotesProvider.notifier);

      // Garlic is already open on the cacık note.
      expect(
        notifier.addMissingForRecipe(recipe('chicken-saute'), ['Garlic']),
        0,
      );

      notifier.toggleItem('note-weekly', 'item-milk');
      expect(
        notifier.addMissingForRecipe(recipe('rice-pudding'), ['milk', 'Rice']),
        2,
      );
      final notes = c.read(shoppingNotesProvider);
      final weekly = notes.firstWhere((n) => n.id == 'note-weekly');
      expect(weekly.items.first.isChecked, isFalse);
      final pudding = notes.firstWhere((n) => n.recipeId == 'rice-pudding');
      expect(pudding.items.map((i) => i.name), ['Rice']);

      expect(
        notifier.addMissingForRecipe(recipe('rice-pudding'), ['Rice']),
        0,
      );
      expect(c.read(shoppingNotesProvider), hasLength(3));
    });

    test('appends to an existing recipe note', () {
      final c = _container();
      final notifier = c.read(shoppingNotesProvider.notifier);
      notifier.toggleItem('note-cacik', 'item-garlic');
      notifier.addMissingForRecipe(recipe('cacik'), ['Garlic', 'Lemon']);
      final cacik = c
          .read(shoppingNotesProvider)
          .firstWhere((n) => n.id == 'note-cacik');
      expect(cacik.items.map((i) => (i.name, i.isChecked)), [
        ('Cucumber', false),
        ('Garlic', false),
        ('Dried mint', false),
        ('Lemon', false),
      ]);
      final ids = cacik.items.map((i) => i.id).toSet();
      expect(ids, hasLength(4));
    });
  });

  group('6. What to cook', () {
    testWidgets('shows ranked cards, badges and the hidden footer',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes');

      expect(find.text('What to cook'), findsOneWidget);
      for (final label in [
        'Allergy-safe',
        'Under 20 min',
        'Vegetarian',
        'Uses expiring',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      final seaBass = _card('baked-sea-bass');
      expect(
        find.descendant(of: seaBass, matching: find.text('100% match')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: seaBass,
          matching: find.text('Uses sea bass – expires in 1 day'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: seaBass, matching: find.text('30 min')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _card('chicken-saute'),
          matching: find.text('80% match – missing garlic'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chicken satay'), findsNothing);
      expect(find.text('Peanut noodle salad'), findsNothing);

      await _scrollTo(
        tester,
        find.text('Hidden: 2 recipes with peanuts (your allergy)'),
      );
      expect(
        find.text('Hidden: 2 recipes with peanuts (your allergy)'),
        findsOneWidget,
      );
    });

    testWidgets('filter chips update the list', (tester) async {
      await pumpAt(tester, '/fridge/recipes');

      await tester.tap(find.byKey(const Key('filter-under20Min')));
      await tester.pumpAndSettle();
      expect(_card('menemen'), findsOneWidget);
      expect(_card('cacik'), findsOneWidget);
      expect(_card('baked-sea-bass'), findsNothing);
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('filter-under20Min')))
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('filter-vegetarian')));
      await tester.tap(find.byKey(const Key('filter-usesExpiring')));
      await tester.pumpAndSettle();
      expect(_card('menemen'), findsNothing);
      expect(_card('pasta-with-yogurt'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-under20Min')));
      await tester.tap(find.byKey(const Key('filter-usesExpiring')));
      await tester.pumpAndSettle();
      expect(_card('chicken-saute'), findsNothing);
      expect(_card('menemen'), findsOneWidget);
    });

    testWidgets('empty filter result offers to clear filters', (tester) async {
      final c = await pumpAt(tester, '/fridge/recipes');
      // Egg and milk allergies leave only chicken and fish recipes, so
      // Vegetarian + Under 20 min matches nothing.
      final p = c.read(profileProvider);
      c.read(profileProvider.notifier).updateDietary(
        allergies: {...p.allergies, Allergen.eggs, Allergen.milk},
        customAllergies: const [],
        diet: Diet.none,
      );
      await tester.tap(find.byKey(const Key('filter-vegetarian')));
      await tester.tap(find.byKey(const Key('filter-under20Min')));
      await tester.pumpAndSettle();

      expect(find.text('No recipes match these filters.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-filters')));
      await tester.pumpAndSettle();
      expect(_card('chicken-saute'), findsOneWidget);
    });

    testWidgets('Allergy-safe chip stays on and explains why',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes');
      await tester.tap(find.byKey(const Key('filter-allergySafe')));
      await tester.pump();
      expect(
        find.text('Recipes with your allergens are always hidden.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('filter-allergySafe')))
            .selected,
        isTrue,
      );
    });

    testWidgets('one tap sends missing ingredients to the shopping list',
        (tester) async {
      final c = await pumpAt(tester, '/fridge/recipes');

      // Garlic is already on the cacık note.
      expect(
        find.descendant(
          of: _card('chicken-saute'),
          matching: find.text('On your shopping list'),
        ),
        findsOneWidget,
      );

      final button = find.byKey(const Key('add-missing-lentil-soup'));
      await _scrollTo(tester, button);
      expect(find.text('Add red lentils to shopping list'), findsOneWidget);
      await tester.tap(button);
      await tester.pump();

      expect(
        find.text('Red lentils added to your shopping list'),
        findsOneWidget,
      );
      final note = c
          .read(shoppingNotesProvider)
          .firstWhere((n) => n.recipeId == 'lentil-soup');
      expect(note.title, 'For lentil soup');
      expect(note.items.single.name, 'Red lentils');
      expect(
        find.descendant(
          of: _card('lentil-soup'),
          matching: find.text('On your shopping list'),
        ),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.text('Notes on your fridge door'), findsOneWidget);
    });

    testWidgets('heart toggles a favorite', (tester) async {
      final c = await pumpAt(tester, '/fridge/recipes');
      expect(c.read(profileProvider).isFavorite('chicken-saute'), isFalse);
      await tester.tap(find.byKey(const Key('favorite-toggle-chicken-saute')));
      await tester.pumpAndSettle();
      expect(c.read(profileProvider).isFavorite('chicken-saute'), isTrue);
      expect(
        find.descendant(
          of: _card('chicken-saute'),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping a card opens ingredients and steps',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes');
      await tester.tap(find.text('Chicken sauté'));
      await tester.pumpAndSettle();

      expect(find.text('25 min · 2 servings'), findsOneWidget);
      expect(find.text('INGREDIENTS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('ingredient-row-Garlic')),
          matching: find.text('Missing'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ingredient-row-Chicken')),
          matching: find.text('In fridge'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ingredient-row-Salt')),
          matching: find.text('Pantry'),
        ),
        findsOneWidget,
      );
      expect(find.text('Start Cooking'), findsOneWidget);
    });

    testWidgets('detail of an allergen recipe shows a warning',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes/chicken-satay');
      expect(find.byKey(const Key('recipe-allergy-warning')), findsOneWidget);
    });

    testWidgets('unknown recipe id is recoverable', (tester) async {
      await pumpAt(tester, '/fridge/recipes/mystery');
      expect(find.text('Recipe not found'), findsOneWidget);
      await tester.tap(find.text('See what to cook'));
      await tester.pumpAndSettle();
      expect(find.text('What to cook'), findsOneWidget);
    });
  });
}
