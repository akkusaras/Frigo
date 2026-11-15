import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/core/theme/app_colors.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';
import 'package:frigo/providers/shopping_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => _today)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<ProviderContainer> _pumpAt(WidgetTester tester, String location) async {
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

Finder _onNote(String noteId, Finder finder) =>
    find.descendant(of: find.byKey(Key('note-$noteId')), matching: finder);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byKey(const Key('shopping-list')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ShoppingNotesNotifier', () {
    test('addNote trims, dedupes and appends a new note', () {
      final c = _container();
      final note = c.read(shoppingNotesProvider.notifier).addNote(
        title: '  Party  ',
        color: NoteColor.yellow,
        items: [' Chips', '', 'chips', 'Lemonade '],
      );
      expect(note, isNotNull);
      final notes = c.read(shoppingNotesProvider);
      expect(notes, hasLength(3));
      expect(notes.last.title, 'Party');
      expect(notes.last.id, 'note-party');
      expect(notes.last.items.map((i) => i.name), ['Chips', 'Lemonade']);
      expect(notes.last.items.map((i) => i.id).toSet(), hasLength(2));
      expect(c.read(shoppingRepositoryProvider).loadNotes(), notes);
      expect(c.read(shoppingOpenItemCountProvider), 7);
    });

    test('addNote rejects a blank title and keeps ids unique', () {
      final c = _container();
      final notifier = c.read(shoppingNotesProvider.notifier);
      expect(notifier.addNote(title: '  ', color: NoteColor.pink), isNull);
      expect(c.read(shoppingNotesProvider), hasLength(2));
      final again = notifier.addNote(title: 'Weekly', color: NoteColor.pink);
      expect(again!.id, 'note-weekly-2');
    });

    test('addItem appends, reopens checked duplicates, skips open ones', () {
      final c = _container();
      final notifier = c.read(shoppingNotesProvider.notifier);
      expect(notifier.addItem('note-weekly', 'Eggs'), isTrue);
      expect(notifier.addItem('note-weekly', 'eggs'), isFalse);
      expect(notifier.addItem('note-weekly', '   '), isFalse);
      expect(notifier.addItem('missing-note', 'Eggs'), isFalse);

      notifier.toggleItem('note-weekly', 'item-milk');
      expect(notifier.addItem('note-weekly', 'Milk'), isTrue);
      final weekly = c
          .read(shoppingNotesProvider)
          .firstWhere((n) => n.id == 'note-weekly');
      expect(weekly.items.map((i) => (i.name, i.isChecked)), [
        ('Milk', false),
        ('Bread', false),
        ('Eggs', false),
      ]);
    });

    test('removeNote and restore', () {
      final c = _container();
      final notifier = c.read(shoppingNotesProvider.notifier);
      final before = c.read(shoppingNotesProvider);
      notifier.removeNote('note-cacik');
      expect(c.read(shoppingNotesProvider).map((n) => n.id), ['note-weekly']);
      notifier.restore(before);
      expect(c.read(shoppingNotesProvider), before);
    });
  });

  group('3. Shopping list', () {
    testWidgets('shows pastel sticky notes with their items', (tester) async {
      await _pumpAt(tester, '/fridge/shopping-list');

      expect(find.text('Shopping list'), findsOneWidget);
      expect(find.text('Notes on your fridge door'), findsOneWidget);
      expect(find.text('EY'), findsOneWidget);

      for (final name in ['For cacık', 'Cucumber', 'Garlic', 'Dried mint']) {
        expect(_onNote('note-cacik', find.text(name)), findsOneWidget);
      }
      for (final name in ['Weekly', 'Milk', 'Bread']) {
        expect(_onNote('note-weekly', find.text(name)), findsOneWidget);
      }

      Color colorOf(String id) =>
          ((tester.widget<Container>(find.byKey(Key('note-$id'))).decoration!
                      as BoxDecoration)
                  .color)!;
      expect(colorOf('note-cacik'), AppColors.noteYellow);
      expect(colorOf('note-weekly'), AppColors.notePink);

      await _scrollTo(tester, find.byKey(const Key('add-note')));
      expect(find.text('+ Add a note'), findsOneWidget);
      expect(
        find.text('Missing ingredients from recipes land here automatically.'),
        findsOneWidget,
      );
      expect(find.text('Open the fridge'), findsOneWidget);
    });

    testWidgets('checkboxes tick items off', (tester) async {
      final c = await _pumpAt(tester, '/fridge/shopping-list');
      final check = find.byKey(const Key('shopping-check-item-garlic'));
      expect(tester.widget<Checkbox>(check).value, isFalse);

      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check).value, isTrue);
      expect(c.read(shoppingOpenItemCountProvider), 4);

      await tester.tap(find.text('Garlic'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check).value, isFalse);
      expect(c.read(shoppingOpenItemCountProvider), 5);
    });

    testWidgets('+ Add a note sticks a new note on the door', (tester) async {
      final c = await _pumpAt(tester, '/fridge/shopping-list');
      await _scrollTo(tester, find.byKey(const Key('add-note')));
      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();

      // A title is required.
      await tester.tap(find.byKey(const Key('note-save')));
      await tester.pumpAndSettle();
      expect(find.text('Give your note a title'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Breakfast',
      );
      await tester.enterText(
        find.byKey(const Key('note-items-field')),
        'Honey, Olives',
      );
      await tester.tap(find.byKey(const Key('note-color-yellow')));
      await tester.tap(find.byKey(const Key('note-save')));
      await tester.pumpAndSettle();

      final note = c.read(shoppingNotesProvider).last;
      expect(note.title, 'Breakfast');
      expect(note.color, NoteColor.yellow);
      expect(note.items.map((i) => i.name), ['Honey', 'Olives']);
      await _scrollTo(tester, find.text('Olives'));
      expect(_onNote(note.id, find.text('Honey')), findsOneWidget);
    });

    testWidgets('add an item to a note and remove a note with undo',
        (tester) async {
      final c = await _pumpAt(tester, '/fridge/shopping-list');
      await tester.tap(find.byKey(const Key('note-add-item-note-weekly')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add-item-field')), 'Eggs');
      await tester.tap(find.byKey(const Key('add-item-confirm')));
      await tester.pumpAndSettle();
      expect(_onNote('note-weekly', find.text('Eggs')), findsOneWidget);

      await tester.tap(find.byKey(const Key('note-remove-note-cacik')));
      await tester.pumpAndSettle();
      expect(find.text('For cacık'), findsNothing);
      expect(find.text('"For cacık" removed'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('For cacık'), findsOneWidget);
      expect(c.read(shoppingNotesProvider), hasLength(2));
    });

    testWidgets('missing recipe ingredients appear as a new note',
        (tester) async {
      await _pumpAt(tester, '/fridge/recipes/lentil-soup');
      final button = find.byKey(const Key('add-missing-lentil-soup'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(find.text('Notes on your fridge door'), findsOneWidget);
      expect(
        _onNote('note-lentil-soup', find.text('For lentil soup')),
        findsOneWidget,
      );
      expect(
        _onNote('note-lentil-soup', find.text('Red lentils')),
        findsOneWidget,
      );
    });

    testWidgets('Open the fridge goes home', (tester) async {
      await _pumpAt(tester, '/fridge/shopping-list');
      await tester.tap(find.byKey(const Key('open-fridge')));
      await tester.pumpAndSettle();
      expect(find.text('My Fridge'), findsOneWidget);
    });
  });
}
