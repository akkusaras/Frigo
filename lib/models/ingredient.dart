import 'package:flutter/foundation.dart';

import 'shelf_category.dart';

/// Normalises an ingredient name for case-insensitive comparisons.
String normalizeIngredientName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// An item currently stored in the user's fridge.
@immutable
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.shelf,
    this.quantity,
    this.expiresOn,
  });

  /// Items expiring within this many days are flagged as "expiring soon".
  static const int expiringSoonDays = 2;

  final String id;
  final String name;
  final ShelfCategory shelf;

  /// Free-form amount, e.g. `1 L` or `6 pcs`.
  final String? quantity;

  /// Calendar day the item expires on (time of day is ignored).
  final DateTime? expiresOn;

  String get normalizedName => normalizeIngredientName(name);

  /// Whole days from [now] until expiry; negative when already expired,
  /// `null` when there is no expiry date.
  int? daysUntilExpiry(DateTime now) {
    final expiry = expiresOn;
    if (expiry == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(expiry.year, expiry.month, expiry.day);
    return (day.difference(today).inHours / 24).round();
  }

  bool isExpiringSoon(DateTime now) {
    final days = daysUntilExpiry(now);
    return days != null && days <= expiringSoonDays;
  }

  bool isExpired(DateTime now) {
    final days = daysUntilExpiry(now);
    return days != null && days < 0;
  }

  /// Short badge shown on the fridge shelf (`1d`, `2d`), or `null` when the
  /// item is not expiring soon.
  String? expiryBadge(DateTime now) {
    if (!isExpiringSoon(now)) return null;
    final days = daysUntilExpiry(now)!;
    return days < 0 ? 'expired' : '${days}d';
  }

  Ingredient copyWith({
    String? id,
    String? name,
    ShelfCategory? shelf,
    String? quantity,
    DateTime? expiresOn,
    bool clearQuantity = false,
    bool clearExpiresOn = false,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      shelf: shelf ?? this.shelf,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      expiresOn: clearExpiresOn ? null : expiresOn ?? this.expiresOn,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Ingredient &&
      other.id == id &&
      other.name == name &&
      other.shelf == shelf &&
      other.quantity == quantity &&
      other.expiresOn == expiresOn;

  @override
  int get hashCode => Object.hash(id, name, shelf, quantity, expiresOn);

  @override
  String toString() => 'Ingredient($name, ${shelf.displayName})';
}
