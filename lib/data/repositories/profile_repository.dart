import 'dart:convert';

import '../../core/persistence/local_store.dart';
import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Persists the signed-in user's profile.
abstract interface class ProfileRepository {
  UserProfile loadProfile();
  void saveProfile(UserProfile profile);

  /// Wipes any saved state and goes back to the mockup's demo profile.
  void resetToDemo();
}

class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({UserProfile? seed})
      : _profile = seed ?? SeedData.userProfile;

  UserProfile _profile;

  @override
  UserProfile loadProfile() => _profile;

  @override
  void saveProfile(UserProfile profile) => _profile = profile;

  @override
  void resetToDemo() => _profile = SeedData.userProfile;
}

/// Persists allergies, diet, favorites and cooking stats as JSON in
/// [LocalStore] so they survive app restarts. Seeds the mockup's demo
/// profile the first time it is read.
class PersistentProfileRepository implements ProfileRepository {
  PersistentProfileRepository(this._store);

  static const _key = 'frigo.profile.v1';

  final LocalStore _store;

  @override
  UserProfile loadProfile() {
    final raw = _store.getString(_key);
    if (raw == null) {
      final seeded = SeedData.userProfile;
      saveProfile(seeded);
      return seeded;
    }
    return _decode(raw);
  }

  @override
  void saveProfile(UserProfile profile) =>
      _store.setString(_key, _encode(profile));

  @override
  void resetToDemo() {
    _store.remove(_key);
    loadProfile();
  }

  static String _encode(UserProfile profile) => jsonEncode({
        'name': profile.name,
        'email': profile.email,
        'allergies': [for (final a in profile.allergies) a.name],
        'customAllergies': profile.customAllergies,
        'diet': profile.diet.name,
        'favoriteRecipeIds': profile.favoriteRecipeIds.toList(),
        'cookedCounts': profile.cookedCounts,
        'itemsSaved': profile.itemsSaved,
      });

  static UserProfile _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile(
      name: map['name'] as String,
      email: map['email'] as String,
      allergies: {
        for (final a in (map['allergies'] as List<dynamic>))
          Allergen.values.byName(a as String),
      },
      customAllergies: [
        for (final a in (map['customAllergies'] as List<dynamic>)) a as String,
      ],
      diet: Diet.values.byName(map['diet'] as String),
      favoriteRecipeIds: {
        for (final id in (map['favoriteRecipeIds'] as List<dynamic>))
          id as String,
      },
      cookedCounts: {
        for (final entry in (map['cookedCounts'] as Map<String, dynamic>).entries)
          entry.key: entry.value as int,
      },
      itemsSaved: map['itemsSaved'] as int,
    );
  }
}
