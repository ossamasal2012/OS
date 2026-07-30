import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/services/notification_service.dart';

class CountdownState {
  const CountdownState({
    required this.totalMs,
    required this.remainingMs,
    required this.isRunning,
    required this.startedAtEpochMs,
    required this.repeat,
  });

  final int totalMs;
  final int remainingMs; // remaining *as of last pause/set* while not running
  final bool isRunning;
  final int? startedAtEpochMs;
  final bool repeat;

  factory CountdownState.initial() => const CountdownState(
        totalMs: 0,
        remainingMs: 0,
        isRunning: false,
        startedAtEpochMs: null,
        repeat: false,
      );

  int remainingMsAt(DateTime now) {
    if (!isRunning || startedAtEpochMs == null) return remainingMs;
    final elapsed = now.millisecondsSinceEpoch - startedAtEpochMs!;
    final left = remainingMs - elapsed;
    return left < 0 ? 0 : left;
  }

  bool get isFinished => isRunning && remainingMsAt(DateTime.now()) <= 0;

  Map<String, dynamic> toJson() => {
        'totalMs': totalMs,
        'remainingMs': remainingMs,
        'isRunning': isRunning,
        'startedAtEpochMs': startedAtEpochMs,
        'repeat': repeat,
      };

  factory CountdownState.fromJson(Map<String, dynamic> json) => CountdownState(
        totalMs: json['totalMs'] as int? ?? 0,
        remainingMs: json['remainingMs'] as int? ?? 0,
        isRunning: json['isRunning'] as bool? ?? false,
        startedAtEpochMs: json['startedAtEpochMs'] as int?,
        repeat: json['repeat'] as bool? ?? false,
      );
}

const int _countdownNotificationId = 500000001;

class CountdownNotifier extends Notifier<CountdownState> {
  Timer? _uiTimer;

  @override
  CountdownState build() {
    final raw = HiveService.settings.get(SettingsKeys.countdownState) as String?;
    final initial = raw == null
        ? CountdownState.initial()
        : CountdownState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (initial.isRunning) _startTicking();
    ref.onDispose(() => _uiTimer?.cancel());
    return initial;
  }

  void _persist() => HiveService.settings.put(SettingsKeys.countdownState, jsonEncode(state.toJson()));

  void _startTicking() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (state.isFinished) {
        _onFinished();
        return;
      }
      state = state; // force listeners to recompute remainingMsAt(now)
    });
  }

  void _onFinished() {
    _uiTimer?.cancel();
    if (state.repeat && state.totalMs > 0) {
      state = CountdownState(
        totalMs: state.totalMs,
        remainingMs: state.totalMs,
        isRunning: true,
        startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        repeat: true,
      );
      _startTicking();
    } else {
      state = CountdownState(
        totalMs: state.totalMs,
        remainingMs: 0,
        isRunning: false,
        startedAtEpochMs: null,
        repeat: state.repeat,
      );
    }
    _persist();
    NotificationService.showNow(
      id: _countdownNotificationId,
      title: 'انتهى العد التنازلي',
      body: 'انتهت المدة المحددة',
      kind: NotifKind.timer,
    );
  }

  void setDuration(Duration d) {
    _uiTimer?.cancel();
    state = CountdownState(
      totalMs: d.inMilliseconds,
      remainingMs: d.inMilliseconds,
      isRunning: false,
      startedAtEpochMs: null,
      repeat: state.repeat,
    );
    _persist();
  }

  void setRepeat(bool value) {
    state = CountdownState(
      totalMs: state.totalMs,
      remainingMs: state.remainingMs,
      isRunning: state.isRunning,
      startedAtEpochMs: state.startedAtEpochMs,
      repeat: value,
    );
    _persist();
  }

  void start() {
    if (state.totalMs <= 0 || state.isRunning) return;
    final remaining = state.remainingMs <= 0 ? state.totalMs : state.remainingMs;
    state = CountdownState(
      totalMs: state.totalMs,
      remainingMs: remaining,
      isRunning: true,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      repeat: state.repeat,
    );
    _startTicking();
    _persist();
  }

  void pause() {
    if (!state.isRunning) return;
    final left = state.remainingMsAt(DateTime.now());
    _uiTimer?.cancel();
    state = CountdownState(
      totalMs: state.totalMs,
      remainingMs: left,
      isRunning: false,
      startedAtEpochMs: null,
      repeat: state.repeat,
    );
    _persist();
  }

  void restart() {
    _uiTimer?.cancel();
    state = CountdownState(
      totalMs: state.totalMs,
      remainingMs: state.totalMs,
      isRunning: false,
      startedAtEpochMs: null,
      repeat: state.repeat,
    );
    _persist();
  }
}

final countdownProvider = NotifierProvider<CountdownNotifier, CountdownState>(
  CountdownNotifier.new,
);
