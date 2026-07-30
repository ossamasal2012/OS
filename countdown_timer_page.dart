import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/countdown_timer/providers/countdown_provider.dart';

class CountdownTimerPage extends ConsumerStatefulWidget {
  const CountdownTimerPage({super.key});

  @override
  ConsumerState<CountdownTimerPage> createState() => _CountdownTimerPageState();
}

class _CountdownTimerPageState extends ConsumerState<CountdownTimerPage> {
  int _days = 0;
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(countdownProvider);
    final notifier = ref.read(countdownProvider.notifier);
    final hasDuration = state.totalMs > 0;
    final remaining = state.remainingMsAt(DateTime.now());
    final (d, h, m, s) = DateTimeUtils.breakDown(Duration(milliseconds: remaining));
    final showPicker = !hasDuration || (!state.isRunning && state.remainingMs == state.totalMs);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.countdownTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: showPicker
                    ? _DurationPicker(
                        days: _days,
                        hours: _hours,
                        minutes: _minutes,
                        seconds: _seconds,
                        onChanged: (d2, h2, m2, s2) => setState(() {
                          _days = d2;
                          _hours = h2;
                          _minutes = m2;
                          _seconds = s2;
                        }),
                      )
                    : _CountdownDisplay(days: d, hours: h, minutes: m, seconds: s),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.countdownRepeat),
              value: state.repeat,
              onChanged: notifier.setRepeat,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasDuration) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.restart,
                      style:
                          OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: Text(l10n.commonRestart),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (showPicker) {
                        final total = Duration(
                          days: _days,
                          hours: _hours,
                          minutes: _minutes,
                          seconds: _seconds,
                        );
                        if (total.inSeconds <= 0) return;
                        notifier.setDuration(total);
                        notifier.start();
                      } else if (state.isRunning) {
                        notifier.pause();
                      } else {
                        notifier.start();
                      }
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: Text(state.isRunning ? l10n.commonPause : l10n.commonStart),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  const _CountdownDisplay({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int days, hours, minutes, seconds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget unit(int value, String label) => Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: theme.textTheme.displayMedium
                  ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (days > 0) ...[unit(days, l10n.countdownDays), const SizedBox(width: 10)],
        unit(hours, l10n.countdownHours),
        const SizedBox(width: 10),
        unit(minutes, l10n.countdownMinutes),
        const SizedBox(width: 10),
        unit(seconds, l10n.countdownSeconds),
      ],
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.onChanged,
  });

  final int days, hours, minutes, seconds;
  final void Function(int days, int hours, int minutes, int seconds) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget wheel(int value, int max, String label, ValueChanged<int> onSet) {
      return Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SizedBox(
            width: 64,
            height: 120,
            child: ListWheelScrollView(
              itemExtent: 40,
              diameterRatio: 1.4,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: value),
              onSelectedItemChanged: onSet,
              children: List.generate(
                max + 1,
                (i) => Center(
                  child: Text(
                    i.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        wheel(days, 30, l10n.countdownDays, (v) => onChanged(v, hours, minutes, seconds)),
        wheel(hours, 23, l10n.countdownHours, (v) => onChanged(days, v, minutes, seconds)),
        wheel(minutes, 59, l10n.countdownMinutes, (v) => onChanged(days, hours, v, seconds)),
        wheel(seconds, 59, l10n.countdownSeconds, (v) => onChanged(days, hours, minutes, v)),
      ],
    );
  }
}
