import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/core/theme/app_colors.dart';
import 'package:frigo/providers/router_provider.dart';

Future<void> pumpAt(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(
          createAppRouter(initialLocation: location),
        ),
      ],
      child: const FrigoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app starts on login with Frigo theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FrigoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Cook with what you already have.'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    final theme = Theme.of(tester.element(find.text('Log in')));
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.charcoal);
    expect(theme.colorScheme.secondary, AppColors.mint);
    expect(theme.colorScheme.error, AppColors.coral);
  });

  testWidgets('login navigates to the fridge', (tester) async {
    await pumpAt(tester, '/login');
    await tester.enterText(find.byKey(const Key('login-email')), 'you@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'secret123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('My Fridge'), findsOneWidget);
    expect(find.text('DAIRY'), findsOneWidget);
    expect(find.text('MEAT AND LEFTOVERS'), findsOneWidget);
    expect(find.text('VEGETABLE DRAWER'), findsOneWidget);
  });

  testWidgets('fridge links to shopping list, profile, add and recipes',
      (tester) async {
    await pumpAt(tester, '/fridge');

    await tester.tap(find.byTooltip('Shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('Notes on your fridge door'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Elif Yılmaz'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Add ingredients'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    await tester.tap(find.text('Scan a receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Check what we found'), findsOneWidget);
    expect(find.text('Receipt scan'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suggest recipes'));
    await tester.pumpAndSettle();
    expect(find.text('What to cook'), findsOneWidget);
    expect(find.text('Under 20 min'), findsOneWidget);
  });

  testWidgets('recipe detail opens cooking mode', (tester) async {
    await pumpAt(tester, '/fridge/recipes/baked-sea-bass');
    expect(find.text('Baked sea bass'), findsOneWidget);

    await tester.tap(find.text('Start Cooking'));
    await tester.pumpAndSettle();
    expect(find.text('Cooking mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start Cooking'), findsOneWidget);
  });

  testWidgets('profile links to favorites and allergies', (tester) async {
    await pumpAt(tester, '/fridge/profile');

    await tester.tap(find.text('Favorite recipes'));
    await tester.pumpAndSettle();
    expect(find.text('Search your favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allergies and diet'));
    await tester.pumpAndSettle();
    expect(find.text("I'M ALLERGIC TO"), findsOneWidget);
    expect(find.text('Sesame'), findsOneWidget);
    expect(find.text('Halal'), findsOneWidget);
  });

  testWidgets('log out returns to login', (tester) async {
    await pumpAt(tester, '/fridge/profile');
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Cook with what you already have.'), findsOneWidget);
  });

  testWidgets('unknown routes show a recoverable error screen',
      (tester) async {
    await pumpAt(tester, '/nowhere');
    expect(find.textContaining('/nowhere'), findsOneWidget);
    await tester.tap(find.text('Open the fridge'));
    await tester.pumpAndSettle();
    expect(find.text('My Fridge'), findsOneWidget);
  });
}
