import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/persistence/local_store.dart';
import 'providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(
          SharedPreferencesLocalStore(prefs),
        ),
      ],
      child: const FrigoApp(),
    ),
  );
}
