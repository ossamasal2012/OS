import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/pomodoro/providers/pomodoro_provider.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  String _phaseLabel(BuildContext context, PomodoroPhase phase) {
    final l10n = context.l10n;
    switch (phase) {
      case PomodoroPhase.work:
        return l10n.pomodoroFocus;
      case PomodoroPhase.shortBreak:
        return l10n.pomodoroShortBreak;
      case PomodoroPhase.longBreak:
        return l10n.pomodoroLongBreak;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final theme = Theme.of(context);
    final remaining = state.remainingMsAt(DateTime.now());
    final progress = 1 - (remaining / state.phaseTotalMs).clamp(0.0, 1.0);
    final isWork = state.phase == PomodoroPhase.work;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pomodoroTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSettingsSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isWork ? theme.colorScheme.primary : theme.colorScheme.tertiary)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _phaseLabel(context, state.phase),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isWork ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                        ),
                        Text(
                          DateTimeUtils.formatDurationClock(Duration(milliseconds: remaining)),
                          style: theme.textTheme.displayMedium
                              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 6,
                    children: List.generate(state.settings.sessionsUntilLongBreak, (i) {
                      final completedInCycle =
                          state.completedWorkSessions % state.settings.sessionsUntilLongBreak;
                      final filled = i < completedInCycle;
                      return Icon(
                        filled ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: theme.colorScheme.primary,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.pomodoroSessionsCompleted}: ${state.completedWorkSessions}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: notifier.skip,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: Text(l10n.pomodoroSkip),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: state.isRunning ? notifier.pause : notifier.start,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: Text(state.isRunning ? l10n.commonPause : l10n.commonStart),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(pomodoroProvider);
    var work = state.settings.workMinutes;
    var brk = state.settings.breakMinutes;
    var longBrk = state.settings.longBreakMinutes;
    var until = state.settings.sessionsUntilLongBreak;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pomodoroSettings, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              _sheetStepper(ctx, l10n.pomodoroWorkDuration, work, 5, 90, (v) => setSheetState(() => work = v)),
              _sheetStepper(ctx, l10n.pomodoroBreakDuration, brk, 1, 30, (v) => setSheetState(() => brk = v)),
              _sheetStepper(ctx, l10n.pomodoroLongBreakDuration, longBrk, 5, 60, (v) => setSheetState(() => longBrk = v)),
              _sheetStepper(ctx, l10n.pomodoroSessionsUntilLongBreak, until, 2, 8, (v) => setSheetState(() => until = v)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.read(pomodoroProvider.notifier).updateSettings(
                        PomodoroSettings(
                          workMinutes: work,
                          breakMinutes: brk,
                          longBreakMinutes: longBrk,
                          sessionsUntilLongBreak: until,
                        ),
                      );
                  Navigator.pop(ctx);
                },
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetStepper(
    BuildContext context,
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.center)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
