import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/stopwatch/providers/stopwatch_provider.dart';

class StopwatchPage extends ConsumerWidget {
  const StopwatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);
    final elapsed = state.elapsedMsAt(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stopwatchTitle)),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _DialPainter(
                    progress: (elapsed % 60000) / 60000,
                    color: theme.colorScheme.primary,
                    trackColor: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Text(
                      DateTimeUtils.formatDurationClock(Duration(milliseconds: elapsed)),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (state.laps.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.laps.length,
                itemBuilder: (context, i) {
                  final lapIndex = state.laps.length - i;
                  final totalMs = state.laps[state.laps.length - 1 - i];
                  final prevMs = lapIndex > 1 ? state.laps[state.laps.length - i - 2] : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.stopwatchLap} $lapIndex'),
                        Text(DateTimeUtils.formatDurationClock(Duration(milliseconds: totalMs - prevMs))),
                        Text(DateTimeUtils.formatDurationClock(Duration(milliseconds: totalMs))),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isRunning
                        ? notifier.lap
                        : (elapsed > 0 ? notifier.reset : null),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: Text(state.isRunning ? l10n.stopwatchLap : l10n.commonReset),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
}

/// A minute-hand instrument-dial face — tick marks every 6°, a sweeping
/// progress arc, echoing the app's astrolabe visual identity.
class _DialPainter extends CustomPainter {
  _DialPainter({required this.progress, required this.color, required this.trackColor});

  final double progress; // 0..1 within the current minute
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 8, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final tickPaint = Paint()..color = color.withOpacity(0.5);
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final isMajor = i % 5 == 0;
      final outer = radius - 22;
      final inner = outer - (isMajor ? 10 : 5);
      final p1 = center + Offset(math.cos(angle) * outer, math.sin(angle) * outer);
      final p2 = center + Offset(math.cos(angle) * inner, math.sin(angle) * inner);
      canvas.drawLine(p1, p2, tickPaint..strokeWidth = isMajor ? 2 : 1);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
