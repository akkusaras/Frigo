import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Persists the signed-in user's profile.
abstract interface class ProfileRepository {
  UserProfile loadProfile();
  void saveProfile(UserProfile profile);
}

class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({UserProfile? seed})
      : _profile = seed ?? SeedData.userProfile;

  UserProfile _profile;

  @override
  UserProfile loadProfile() => _profile;

  @override
  void saveProfile(UserProfile profile) => _profile = profile;
}
