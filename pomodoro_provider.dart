import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/features/pomodoro/models/pomodoro_session.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroSettings {
  const PomodoroSettings({
    required this.workMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.sessionsUntilLongBreak,
  });

  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int sessionsUntilLongBreak;
}

class PomodoroState {
  const PomodoroState({
    required this.phase,
    required this.isRunning,
    required this.remainingMs,
    required this.startedAtEpochMs,
    required this.completedWorkSessions,
    required this.settings,
  });

  final PomodoroPhase phase;
  final bool isRunning;
  final int remainingMs;
  final int? startedAtEpochMs;
  final int completedWorkSessions;
  final PomodoroSettings settings;

  int get phaseTotalMs {
    switch (phase) {
      case PomodoroPhase.work:
        return settings.workMinutes * 60000;
      case PomodoroPhase.shortBreak:
        return settings.breakMinutes * 60000;
      case PomodoroPhase.longBreak:
        return settings.longBreakMinutes * 60000;
    }
  }

  int remainingMsAt(DateTime now) {
    if (!isRunning || startedAtEpochMs == null) return remainingMs;
    final elapsed = now.millisecondsSinceEpoch - startedAtEpochMs!;
    final left = remainingMs - elapsed;
    return left < 0 ? 0 : left;
  }
}

const int _pomodoroNotificationId = 500000002;

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _uiTimer;

  @override
  PomodoroState build() {
    final box = HiveService.settings;
    final settings = PomodoroSettings(
      workMinutes: box.get(SettingsKeys.pomodoroWorkMinutes, defaultValue: 25) as int,
      breakMinutes: box.get(SettingsKeys.pomodoroBreakMinutes, defaultValue: 5) as int,
      longBreakMinutes: box.get(SettingsKeys.pomodoroLongBreakMinutes, defaultValue: 15) as int,
      sessionsUntilLongBreak:
          box.get(SettingsKeys.pomodoroSessionsUntilLongBreak, defaultValue: 4) as int,
    );
    ref.onDispose(() => _uiTimer?.cancel());
    return PomodoroState(
      phase: PomodoroPhase.work,
      isRunning: false,
      remainingMs: settings.workMinutes * 60000,
      startedAtEpochMs: null,
      completedWorkSessions: 0,
      settings: settings,
    );
  }

  void updateSettings(PomodoroSettings s) {
    final box = HiveService.settings;
    box.put(SettingsKeys.pomodoroWorkMinutes, s.workMinutes);
    box.put(SettingsKeys.pomodoroBreakMinutes, s.breakMinutes);
    box.put(SettingsKeys.pomodoroLongBreakMinutes, s.longBreakMinutes);
    box.put(SettingsKeys.pomodoroSessionsUntilLongBreak, s.sessionsUntilLongBreak);
    if (!state.isRunning) {
      state = PomodoroState(
        phase: state.phase,
        isRunning: false,
        remainingMs: state.phase == PomodoroPhase.work
            ? s.workMinutes * 60000
            : state.remainingMs,
        startedAtEpochMs: null,
        completedWorkSessions: state.completedWorkSessions,
        settings: s,
      );
    } else {
      state = PomodoroState(
        phase: state.phase,
        isRunning: state.isRunning,
        remainingMs: state.remainingMs,
        startedAtEpochMs: state.startedAtEpochMs,
        completedWorkSessions: state.completedWorkSessions,
        settings: s,
      );
    }
  }

  void _tick() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (state.remainingMsAt(DateTime.now()) <= 0) {
        _advancePhase();
      } else {
        state = state; // rebuild listeners
      }
    });
  }

  void _advancePhase() {
    _uiTimer?.cancel();
    final finishedPhase = state.phase;
    var sessions = state.completedWorkSessions;

    if (finishedPhase == PomodoroPhase.work) {
      sessions++;
      HiveService.pomodoroSessions.put(
        DateTime.now().microsecondsSinceEpoch.toString(),
        PomodoroSession(minutes: state.settings.workMinutes),
      );
    }

    final nextPhase = finishedPhase == PomodoroPhase.work
        ? (sessions % state.settings.sessionsUntilLongBreak == 0
            ? PomodoroPhase.longBreak
            : PomodoroPhase.shortBreak)
        : PomodoroPhase.work;

    state = PomodoroState(
      phase: nextPhase,
      isRunning: false,
      remainingMs: _totalFor(nextPhase, state.settings),
      startedAtEpochMs: null,
      completedWorkSessions: sessions,
      settings: state.settings,
    );

    NotificationService.showNow(
      id: _pomodoroNotificationId,
      title: finishedPhase == PomodoroPhase.work ? 'أحسنت! حان وقت الاستراحة' : 'انتهت الاستراحة',
      body: finishedPhase == PomodoroPhase.work ? 'خذ استراحة قصيرة' : 'حان وقت التركيز من جديد',
      kind: NotifKind.timer,
    );
  }

  int _totalFor(PomodoroPhase phase, PomodoroSettings s) {
    switch (phase) {
      case PomodoroPhase.work:
        return s.workMinutes * 60000;
      case PomodoroPhase.shortBreak:
        return s.breakMinutes * 60000;
      case PomodoroPhase.longBreak:
        return s.longBreakMinutes * 60000;
    }
  }

  void start() {
    if (state.isRunning) return;
    state = PomodoroState(
      phase: state.phase,
      isRunning: true,
      remainingMs: state.remainingMs,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      completedWorkSessions: state.completedWorkSessions,
      settings: state.settings,
    );
    _tick();
  }

  void pause() {
    if (!state.isRunning) return;
    final left = state.remainingMsAt(DateTime.now());
    _uiTimer?.cancel();
    state = PomodoroState(
      phase: state.phase,
      isRunning: false,
      remainingMs: left,
      startedAtEpochMs: null,
      completedWorkSessions: state.completedWorkSessions,
      settings: state.settings,
    );
  }

  void skip() => _advancePhase();

  void resetToWork() {
    _uiTimer?.cancel();
    state = PomodoroState(
      phase: PomodoroPhase.work,
      isRunning: false,
      remainingMs: state.settings.workMinutes * 60000,
      startedAtEpochMs: null,
      completedWorkSessions: 0,
      settings: state.settings,
    );
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);
