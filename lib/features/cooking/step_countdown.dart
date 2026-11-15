import 'package:flutter/foundation.dart';

/// Immutable state of one step's countdown timer in Cooking Mode.
@immutable
class StepCountdown {
  const StepCountdown({
    required this.total,
    Duration? remaining,
    this.isRunning = false,
  }) : remaining = remaining ?? total;

  final Duration total;
  final Duration remaining;
  final bool isRunning;

  bool get isFinished => remaining <= Duration.zero;

  /// Untouched since it was created or reset.
  bool get isPristine => !isRunning && remaining == total;

  /// Elapsed share of the timer, `0.0` → `1.0`.
  double get progress {
    if (total <= Duration.zero) return 1;
    final done = 1 - remaining.inMilliseconds / total.inMilliseconds;
    return done.clamp(0.0, 1.0);
  }

  StepCountdown start() => isFinished || isRunning
      ? this
      : StepCountdown(total: total, remaining: remaining, isRunning: true);

  StepCountdown pause() => isRunning
      ? StepCountdown(total: total, remaining: remaining)
      : this;

  StepCountdown reset() => StepCountdown(total: total);

  /// Advances a running timer by [elapsed]; stops at zero.
  StepCountdown tick(Duration elapsed) {
    if (!isRunning) return this;
    final next = remaining - elapsed;
    if (next <= Duration.zero) {
      return StepCountdown(total: total, remaining: Duration.zero);
    }
    return StepCountdown(total: total, remaining: next, isRunning: true);
  }

  @override
  bool operator ==(Object other) =>
      other is StepCountdown &&
      other.total == total &&
      other.remaining == remaining &&
      other.isRunning == isRunning;

  @override
  int get hashCode => Object.hash(total, remaining, isRunning);

  @override
  String toString() =>
      'StepCountdown($remaining / $total${isRunning ? ', running' : ''})';
}
