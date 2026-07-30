import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/services/hive_service.dart';

class LapEntry {
  const LapEntry(this.index, this.totalMs, this.splitMs);
  final int index;
  final int totalMs;
  final int splitMs;
}

class StopwatchState {
  const StopwatchState({
    required this.isRunning,
    required this.accumulatedMs,
    required this.startedAtEpochMs,
    required this.laps,
  });

  final bool isRunning;

  /// Elapsed time banked from *previous* runs (before the most recent
  /// start). While running, total elapsed = accumulatedMs + (now -
  /// startedAtEpochMs).
  final int accumulatedMs;
  final int? startedAtEpochMs;
  final List<int> laps; // total-ms at each lap press

  factory StopwatchState.initial() =>
      const StopwatchState(isRunning: false, accumulatedMs: 0, startedAtEpochMs: null, laps: []);

  int elapsedMsAt(DateTime now) {
    if (!isRunning || startedAtEpochMs == null) return accumulatedMs;
    return accumulatedMs + (now.millisecondsSinceEpoch - startedAtEpochMs!);
  }

  Map<String, dynamic> toJson() => {
        'isRunning': isRunning,
        'accumulatedMs': accumulatedMs,
        'startedAtEpochMs': startedAtEpochMs,
        'laps': laps,
      };

  factory StopwatchState.fromJson(Map<String, dynamic> json) => StopwatchState(
        isRunning: json['isRunning'] as bool? ?? false,
        accumulatedMs: json['accumulatedMs'] as int? ?? 0,
        startedAtEpochMs: json['startedAtEpochMs'] as int?,
        laps: (json['laps'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      );
}

class StopwatchNotifier extends Notifier<StopwatchState> {
  Timer? _uiTimer;

  @override
  StopwatchState build() {
    final raw = HiveService.settings.get(SettingsKeys.stopwatchState) as String?;
    final initial = raw == null
        ? StopwatchState.initial()
        : StopwatchState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (initial.isRunning) _startTicking();
    ref.onDispose(() => _uiTimer?.cancel());
    return initial;
  }

  void _persist() {
    HiveService.settings.put(SettingsKeys.stopwatchState, jsonEncode(state.toJson()));
  }

  void _startTicking() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      // Just forces listeners to rebuild with a fresh elapsedMsAt(now); the
      // persisted state object itself doesn't need to change every tick.
      state = state;
    });
  }

  void start() {
    if (state.isRunning) return;
    state = StopwatchState(
      isRunning: true,
      accumulatedMs: state.accumulatedMs,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      laps: state.laps,
    );
    _startTicking();
    _persist();
  }

  void pause() {
    if (!state.isRunning) return;
    final elapsed = state.elapsedMsAt(DateTime.now());
    _uiTimer?.cancel();
    state = StopwatchState(
      isRunning: false,
      accumulatedMs: elapsed,
      startedAtEpochMs: null,
      laps: state.laps,
    );
    _persist();
  }

  void lap() {
    if (!state.isRunning) return;
    final elapsed = state.elapsedMsAt(DateTime.now());
    state = StopwatchState(
      isRunning: state.isRunning,
      accumulatedMs: state.accumulatedMs,
      startedAtEpochMs: state.startedAtEpochMs,
      laps: [...state.laps, elapsed],
    );
    _persist();
  }

  void reset() {
    _uiTimer?.cancel();
    state = StopwatchState.initial();
    _persist();
  }
}

final stopwatchProvider = NotifierProvider<StopwatchNotifier, StopwatchState>(
  StopwatchNotifier.new,
);
