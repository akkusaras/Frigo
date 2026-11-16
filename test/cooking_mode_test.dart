import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/features/cooking/step_countdown.dart';
import 'package:frigo/features/recipes/recipe_widgets.dart';
import 'package:frigo/providers/profile_provider.dart';

import 'recipe_suggestions_test.dart' show pumpAt;

String _display(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('timer-display'))).data!;

String _status(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('timer-status'))).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

void main() {
  group('StepCountdown', () {
    const total = Duration(minutes: 2);

    test('start, tick, pause and reset', () {
      var t = const StepCountdown(total: total);
      expect(t.isPristine, isTrue);
      expect(t.tick(const Duration(seconds: 5)), t);

      t = t.start().tick(const Duration(seconds: 30));
      expect(t.remaining, const Duration(seconds: 90));
      expect(t.isRunning, isTrue);
      expect(t.progress, closeTo(0.25, 1e-9));

      t = t.pause();
      expect(t.isRunning, isFalse);
      expect(t.tick(const Duration(seconds: 10)).remaining,
          const Duration(seconds: 90));

      expect(t.reset(), const StepCountdown(total: total));
    });

    test('stops at zero and cannot restart until reset', () {
      final done = const StepCountdown(total: total)
          .start()
          .tick(const Duration(minutes: 5));
      expect(done.remaining, Duration.zero);
      expect(done.isFinished, isTrue);
      expect(done.isRunning, isFalse);
      expect(done.start(), done);
      expect(done.reset().isPristine, isTrue);
    });

    test('formats clocks', () {
      expect(formatClock(const Duration(minutes: 8)), '08:00');
      expect(formatClock(const Duration(seconds: 61)), '01:01');
      expect(formatClock(const Duration(hours: 1, seconds: 5)), '1:00:05');
      expect(formatClock(const Duration(seconds: -3)), '00:00');
    });
  });

  group('Cooking Mode', () {
    testWidgets('timer starts, pauses, resumes and resets', (tester) async {
      await pumpAt(tester, '/fridge/recipes/baked-sea-bass/cook');

      expect(find.text('Cooking mode'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(_display(tester), '08:00');
      expect(_status(tester), '8 min step');
      expect(find.text('Start'), findsOneWidget);

      await _tap(tester, 'timer-toggle');
      await tester.pump(const Duration(seconds: 3));
      expect(_display(tester), '07:57');
      expect(_status(tester), 'Running');

      await _tap(tester, 'timer-toggle');
      expect(_status(tester), 'Paused');
      await tester.pump(const Duration(seconds: 5));
      expect(_display(tester), '07:57');
      expect(find.text('Resume'), findsOneWidget);

      await _tap(tester, 'timer-toggle');
      await tester.pump(const Duration(seconds: 2));
      expect(_display(tester), '07:55');

      await _tap(tester, 'timer-reset');
      expect(_display(tester), '08:00');
      expect(_status(tester), '8 min step');
      await tester.pump(const Duration(seconds: 2));
      expect(_display(tester), '08:00');
    });

    testWidgets('every step has its own timer; Next and Previous work',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes/menemen/cook');

      final previous = tester.widget<OutlinedButton>(
        find.byKey(const Key('step-previous')),
      );
      expect(previous.onPressed, isNull);

      await _tap(tester, 'timer-toggle');
      await tester.pump(const Duration(seconds: 10));

      await _tap(tester, 'step-next');
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(_display(tester), '06:00');
      expect(find.textContaining('Grate in the tomatoes'), findsOneWidget);
      // Step 1 keeps running in the background.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Step 1 · 03:45'), findsOneWidget);

      await _tap(tester, 'step-next');
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(_display(tester), '03:00');
      expect(find.byKey(const Key('step-next')), findsNothing);
      expect(find.byKey(const Key('finish-cooking')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('running-timer-0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('running-timer-0')));
      await tester.pump();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(_display(tester), '03:45');

      await _tap(tester, 'step-next');
      await _tap(tester, 'step-previous');
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('finished timer alerts and locks until reset',
        (tester) async {
      await pumpAt(tester, '/fridge/recipes/cacik/cook');

      await _tap(tester, 'timer-toggle');
      await tester.pump(const Duration(minutes: 3));
      await tester.pump();

      expect(_display(tester), '00:00');
      expect(_status(tester), 'Done');
      expect(find.text('Step 1 timer is done'), findsOneWidget);
      final toggle = tester.widget<FilledButton>(
        find.byKey(const Key('timer-toggle')),
      );
      expect(toggle.onPressed, isNull);

      await _tap(tester, 'timer-reset');
      expect(_display(tester), '03:00');
    });

    testWidgets('finishing counts the meal and returns to the fridge',
        (tester) async {
      final c = await pumpAt(tester, '/fridge/recipes/menemen/cook');
      final before = c.read(profileProvider).timesCooked('menemen');

      await _tap(tester, 'step-next');
      await _tap(tester, 'step-next');
      await tester.tap(find.byKey(const Key('finish-cooking')));
      await tester.pumpAndSettle();

      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('Enjoy your menemen!'), findsOneWidget);
      expect(c.read(profileProvider).timesCooked('menemen'), before + 1);
    });

    testWidgets('finishing a recipe that uses an expiring item lifts the '
        'Items saved counter', (tester) async {
      // Baked sea bass uses sea bass, which expires tomorrow (1d) in the
      // seed fridge — menemen's ingredients (used above) are all far from
      // expiry, so that cook left this counter untouched.
      final c = await pumpAt(tester, '/fridge/recipes/baked-sea-bass/cook');
      final before = c.read(profileProvider).itemsSaved;

      await _tap(tester, 'step-next');
      await _tap(tester, 'step-next');
      await tester.tap(find.byKey(const Key('finish-cooking')));
      await tester.pumpAndSettle();

      expect(c.read(profileProvider).itemsSaved, before + 1);
    });
  });
}
