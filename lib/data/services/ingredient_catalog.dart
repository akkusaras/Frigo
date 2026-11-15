import '../../models/models.dart';

/// A known ingredient with its usual shelf and typical fridge life.
class CatalogEntry {
  const CatalogEntry(this.name, this.shelf, this.shelfLifeDays);

  final String name;
  final ShelfCategory shelf;

  /// Typical number of days the item keeps in the fridge.
  final int shelfLifeDays;
}

/// Local ingredient dictionary powering autocomplete chips, automatic shelf
/// assignment and estimated expiry dates. Designed to be swapped for a remote
/// product database later.
class IngredientCatalog {
  const IngredientCatalog({this.entries = defaultEntries});

  final List<CatalogEntry> entries;

  static const defaultEntries = <CatalogEntry>[
    // Dairy
    CatalogEntry('Milk', ShelfCategory.dairy, 5),
    CatalogEntry('Cheese', ShelfCategory.dairy, 14),
    CatalogEntry('Feta cheese', ShelfCategory.dairy, 10),
    CatalogEntry('Eggs', ShelfCategory.dairy, 14),
    CatalogEntry('Yogurt', ShelfCategory.dairy, 7),
    CatalogEntry('Butter', ShelfCategory.dairy, 30),
    CatalogEntry('Cream', ShelfCategory.dairy, 5),
    CatalogEntry('Kefir', ShelfCategory.dairy, 7),
    CatalogEntry('Ayran', ShelfCategory.dairy, 5),
    // Meat and leftovers
    CatalogEntry('Chicken', ShelfCategory.meatAndLeftovers, 2),
    CatalogEntry('Chicken breast', ShelfCategory.meatAndLeftovers, 2),
    CatalogEntry('Ground beef', ShelfCategory.meatAndLeftovers, 2),
    CatalogEntry('Lamb', ShelfCategory.meatAndLeftovers, 3),
    CatalogEntry('Sea bass', ShelfCategory.meatAndLeftovers, 1),
    CatalogEntry('Salmon', ShelfCategory.meatAndLeftovers, 2),
    CatalogEntry('Sausage', ShelfCategory.meatAndLeftovers, 7),
    CatalogEntry('Lentil soup', ShelfCategory.meatAndLeftovers, 3),
    CatalogEntry('Leftover rice', ShelfCategory.meatAndLeftovers, 3),
    // Vegetable drawer
    CatalogEntry('Spinach', ShelfCategory.vegetableDrawer, 4),
    CatalogEntry('Spinach, frozen', ShelfCategory.vegetableDrawer, 90),
    CatalogEntry('Tomato', ShelfCategory.vegetableDrawer, 6),
    CatalogEntry('Pepper', ShelfCategory.vegetableDrawer, 7),
    CatalogEntry('Carrot', ShelfCategory.vegetableDrawer, 14),
    CatalogEntry('Cucumber', ShelfCategory.vegetableDrawer, 6),
    CatalogEntry('Lemon', ShelfCategory.vegetableDrawer, 14),
    CatalogEntry('Onion', ShelfCategory.vegetableDrawer, 21),
    CatalogEntry('Garlic', ShelfCategory.vegetableDrawer, 30),
    CatalogEntry('Parsley', ShelfCategory.vegetableDrawer, 5),
    CatalogEntry('Dried mint', ShelfCategory.vegetableDrawer, 180),
    CatalogEntry('Zucchini', ShelfCategory.vegetableDrawer, 6),
    CatalogEntry('Eggplant', ShelfCategory.vegetableDrawer, 6),
    CatalogEntry('Lettuce', ShelfCategory.vegetableDrawer, 5),
    CatalogEntry('Mushrooms', ShelfCategory.vegetableDrawer, 5),
  ];

  static const _dairyWords = [
    'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'kefir', //
    'ayran', 'egg', 'labneh',
  ];
  static const _meatWords = [
    'chicken', 'beef', 'lamb', 'meat', 'mince', 'fish', 'bass', 'salmon', //
    'tuna', 'turkey', 'sausage', 'sucuk', 'leftover', 'soup', 'stew',
  ];

  CatalogEntry? lookup(String name) {
    final key = normalizeIngredientName(name);
    for (final entry in entries) {
      if (normalizeIngredientName(entry.name) == key) return entry;
    }
    return null;
  }

  /// Autocomplete suggestions for [query]: prefix matches first, then other
  /// substring matches. An empty query returns no suggestions.
  List<String> suggestions(String query, {int limit = 6}) {
    final key = normalizeIngredientName(query);
    if (key.isEmpty) return const [];
    final prefix = <String>[];
    final contains = <String>[];
    for (final entry in entries) {
      final name = normalizeIngredientName(entry.name);
      if (name.startsWith(key)) {
        prefix.add(entry.name);
      } else if (name.contains(key)) {
        contains.add(entry.name);
      }
    }
    return [...prefix, ...contains].take(limit).toList();
  }

  /// Best-guess shelf for any ingredient name, known or not.
  ShelfCategory shelfFor(String name) {
    final known = lookup(name);
    if (known != null) return known.shelf;
    final key = normalizeIngredientName(name);
    if (_meatWords.any(key.contains)) return ShelfCategory.meatAndLeftovers;
    if (_dairyWords.any(key.contains)) return ShelfCategory.dairy;
    return ShelfCategory.vegetableDrawer;
  }

  /// Estimated expiry for a known ingredient, `null` for unknown ones.
  DateTime? estimatedExpiry(String name, DateTime now) {
    final known = lookup(name);
    if (known == null) return null;
    return DateTime(now.year, now.month, now.day + known.shelfLifeDays);
  }

  /// Display-friendly casing: the catalog spelling when known, otherwise the
  /// trimmed input with an upper-case first letter.
  String canonicalName(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return cleaned;
    return lookup(cleaned)?.name ??
        cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}

/// One ingredient detected by a (mock) photo or receipt scan.
class DetectedIngredient {
  const DetectedIngredient({
    required this.name,
    required this.shelf,
    this.confident = true,
  });

  final String name;
  final ShelfCategory shelf;

  /// Low-confidence detections start unticked so the user can opt in.
  final bool confident;
}

/// Mock vision / OCR scanner. Returns realistic, deterministic detections so
/// the confirmation flow can be exercised end to end before a real Vision
/// API is wired in.
class MockIngredientScanner {
  const MockIngredientScanner();

  List<DetectedIngredient> scanPhoto() => const [
        DetectedIngredient(
          name: 'Cucumber',
          shelf: ShelfCategory.vegetableDrawer,
        ),
        DetectedIngredient(
          name: 'Spinach',
          shelf: ShelfCategory.vegetableDrawer,
        ),
        DetectedIngredient(name: 'Feta cheese', shelf: ShelfCategory.dairy),
        DetectedIngredient(name: 'Garlic', shelf: ShelfCategory.vegetableDrawer),
        DetectedIngredient(
          name: 'Zucchini',
          shelf: ShelfCategory.vegetableDrawer,
          confident: false,
        ),
      ];

  List<DetectedIngredient> scanReceipt() => const [
        DetectedIngredient(name: 'Milk', shelf: ShelfCategory.dairy),
        DetectedIngredient(
          name: 'Cucumber',
          shelf: ShelfCategory.vegetableDrawer,
        ),
        DetectedIngredient(
          name: 'Ground beef',
          shelf: ShelfCategory.meatAndLeftovers,
        ),
        DetectedIngredient(name: 'Kefir', shelf: ShelfCategory.dairy),
        DetectedIngredient(
          name: 'Parsley',
          shelf: ShelfCategory.vegetableDrawer,
          confident: false,
        ),
      ];
}
