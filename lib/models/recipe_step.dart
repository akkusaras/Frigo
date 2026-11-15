import 'package:flutter/foundation.dart';

/// One guided step in Cooking Mode, each with its own countdown timer.
@immutable
class RecipeStep {
  const RecipeStep({required this.instruction, required this.duration});

  final String instruction;

  /// Length of the step's countdown timer.
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is RecipeStep &&
      other.instruction == instruction &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(instruction, duration);

  @override
  String toString() => 'RecipeStep($instruction, $duration)';
}
