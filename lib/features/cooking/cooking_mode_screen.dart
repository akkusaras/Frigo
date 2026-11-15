import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/profile_provider.dart';
import '../../providers/repository_providers.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/recipe_widgets.dart';
import 'step_countdown.dart';

/// Cooking Mode — guided, step-by-step view of a recipe where every step
/// has its own countdown timer (start, pause, reset).
class CookingModeScreen extends ConsumerWidget {
  const CookingModeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeRepositoryProvider).findById(recipeId);
    if (recipe == null) return RecipeNotFound(recipeId: recipeId);
    return _CookingSession(key: ValueKey(recipe.id), recipe: recipe);
  }
}

class _CookingSession extends ConsumerStatefulWidget {
  const _CookingSession({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_CookingSession> createState() => _CookingSessionState();
}

class _CookingSessionState extends ConsumerState<_CookingSession> {
  static const _tickInterval = Duration(seconds: 1);

  late List<StepCountdown> _timers;
  int _index = 0;
  Timer? _ticker;

  List<RecipeStep> get _steps => widget.recipe.steps;
  bool get _isLast => _index >= _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _timers = [for (final s in _steps) StepCountdown(total: s.duration)];
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    final anyRunning = _timers.any((t) => t.isRunning);
    if (anyRunning && _ticker == null) {
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    } else if (!anyRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    final finished = <int>[];
    setState(() {
      for (var i = 0; i < _timers.length; i++) {
        final before = _timers[i];
        final after = before.tick(_tickInterval);
        if (before.isRunning && after.isFinished) finished.add(i);
        _timers[i] = after;
      }
      _syncTicker();
    });
    for (final i in finished) {
      _announceDone(i);
    }
  }

  void _announceDone(int stepIndex) {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    final label = 'Step ${stepIndex + 1} timer is done';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          action: stepIndex == _index
              ? null
              : SnackBarAction(
                  label: 'Go to step',
                  textColor: AppColors.mint,
                  onPressed: () => _goTo(stepIndex),
                ),
        ),
      );
  }

  void _update(int stepIndex, StepCountdown Function(StepCountdown) change) {
    setState(() {
      _timers[stepIndex] = change(_timers[stepIndex]);
      _syncTicker();
    });
  }

  void _goTo(int stepIndex) {
    if (!mounted) return;
    setState(() => _index = stepIndex.clamp(0, _steps.length - 1));
  }

  void _finish() {
    final recipe = widget.recipe;
    ref.read(profileProvider.notifier).recordCooked(recipe.id);
    final messenger = ScaffoldMessenger.of(context);
    context.goToFridge();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Enjoy your ${recipe.title.toLowerCase()}!')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasSteps = _steps.isNotEmpty;
    final others = [
      for (final (i, t) in _timers.indexed)
        if (i != _index && t.isRunning) (i, t),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Cooking mode',
              subtitle: widget.recipe.title,
              showBack: true,
            ),
            Expanded(
              child: !hasSteps
                  ? Center(
                      child: Text(
                        'This recipe has no steps yet.',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        Text(
                          'Step ${_index + 1} of ${_steps.length}',
                          key: const Key('step-counter'),
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / _steps.length,
                            minHeight: 6,
                            color: AppColors.mint,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _steps[_index].instruction,
                              key: const Key('step-instruction'),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _TimerPanel(
                          countdown: _timers[_index],
                          onStart: () => _update(_index, (t) => t.start()),
                          onPause: () => _update(_index, (t) => t.pause()),
                          onReset: () => _update(_index, (t) => t.reset()),
                        ),
                        if (others.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionLabel('Other timers running'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (i, t) in others)
                                ActionChip(
                                  key: Key('running-timer-$i'),
                                  avatar: const Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Step ${i + 1} · '
                                    '${formatClock(t.remaining)}',
                                  ),
                                  onPressed: () => _goTo(i),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton.icon(
            key: const Key('step-previous'),
            onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
          ),
          if (!hasSteps || _isLast)
            FilledButton(
              key: const Key('finish-cooking'),
              onPressed: _finish,
              child: const Text('Finish cooking'),
            )
          else
            FilledButton.icon(
              key: const Key('step-next'),
              onPressed: () => _goTo(_index + 1),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next step'),
            ),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.countdown,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  final StepCountdown countdown;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final finished = countdown.isFinished;
    final running = countdown.isRunning;

    final String toggleLabel;
    final IconData toggleIcon;
    if (running) {
      toggleLabel = 'Pause';
      toggleIcon = Icons.pause_rounded;
    } else if (countdown.isPristine) {
      toggleLabel = 'Start';
      toggleIcon = Icons.play_arrow_rounded;
    } else {
      toggleLabel = 'Resume';
      toggleIcon = Icons.play_arrow_rounded;
    }

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: countdown.progress,
                strokeWidth: 10,
                color: finished ? AppColors.readyGreen : AppColors.mint,
                backgroundColor: AppColors.border,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatClock(countdown.remaining),
                      key: const Key('timer-display'),
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 40,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      finished
                          ? 'Done'
                          : running
                          ? 'Running'
                          : countdown.isPristine
                          ? '${countdown.total.inMinutes} min step'
                          : 'Paused',
                      key: const Key('timer-status'),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('timer-toggle'),
              onPressed: finished ? null : (running ? onPause : onStart),
              icon: Icon(toggleIcon),
              label: Text(toggleLabel),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              key: const Key('timer-reset'),
              onPressed: countdown.isPristine ? null : onReset,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
