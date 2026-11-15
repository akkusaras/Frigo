import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/recipe_matcher.dart';

/// Stateless recipe ranking / allergy engine.
final recipeMatcherProvider = Provider<RecipeMatcher>(
  (ref) => const RecipeMatcher(),
);
