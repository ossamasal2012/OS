import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/features/alarms/alarm_sound_resolver.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/alarms/repositories/alarm_repository.dart';

class AlarmsNotifier extends Notifier<List<Alarm>> {
  final AlarmRepository _repo = AlarmRepositoryImpl();

  @override
  List<Alarm> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> _reschedule(Alarm alarm) async {
    // Always start from a clean slate for this alarm's id space, then
    // re-add whichever occurrences are currently relevant.
    await NotificationService.cancelAllOccurrencesForAlarm(alarm.id, alarm.daySlots);
    if (!alarm.isEnabled) return;

    final resolved = AlarmSoundResolver.resolve(alarm);
    for (final slot in alarm.daySlots) {
      await NotificationService.scheduleAlarmOccurrence(
        alarmId: alarm.id,
        daySlot: slot,
        time: alarm.timeToday(),
        label: alarm.label,
        sound: resolved.sound,
        channelId: resolved.channelId,
        payload: 'alarm:${alarm.id}',
      );
    }
  }

  Future<void> add(Alarm alarm) async {
    final result = await _repo.add(alarm);
    result.fold((a) {
      _reschedule(a);
      _refresh();
    }, (_) => null);
  }

  Future<void> update(Alarm alarm) async {
    final result = await _repo.update(alarm);
    result.fold((a) {
      _reschedule(a);
      _refresh();
    }, (_) => null);
  }

  Future<void> toggleEnabled(Alarm alarm) => update(alarm.copyWith(isEnabled: !alarm.isEnabled));

  Future<void> delete(String id) async {
    final alarm = _repo.getById(id);
    if (alarm != null) {
      await NotificationService.cancelAllOccurrencesForAlarm(id, alarm.daySlots);
    }
    final result = await _repo.delete(id);
    result.fold((_) => _refresh(), (_) => null);
  }

  /// Called when the user taps the "snooze" action on a ringing alarm
  /// notification, or the Snooze button on [AlarmRingingPage].
  Future<void> snooze(String alarmId) async {
    final alarm = _repo.getById(alarmId);
    if (alarm == null) return;
    final resolved = AlarmSoundResolver.resolve(alarm);
    await NotificationService.snoozeAlarm(
      alarmId: alarm.id,
      minutes: alarm.snoozeMinutes,
      label: alarm.label,
      sound: resolved.sound,
      channelId: resolved.channelId,
      payload: 'alarm:${alarm.id}',
    );
  }

  /// Re-applies every enabled alarm's schedule. Call this once on app start
  /// as a belt-and-braces fallback alongside the OS-level boot receiver
  /// (see README) — cheap, idempotent, and guarantees schedules can never
  /// silently drift out of sync with what's saved in Hive.
  Future<void> rescheduleAll() async {
    for (final alarm in _repo.getAll().where((a) => a.isEnabled)) {
      await _reschedule(alarm);
    }
  }
}

final alarmsProvider = NotifierProvider<AlarmsNotifier, List<Alarm>>(AlarmsNotifier.new);

final sortedAlarmsProvider = Provider<List<Alarm>>((ref) {
  final alarms = [...ref.watch(alarmsProvider)];
  alarms.sort((a, b) {
    final byTime = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    if (byTime != 0) return byTime;
    return a.label.compareTo(b.label);
  });
  return alarms;
});

/// The next alarm that will actually ring, for the Dashboard's "next alarm"
/// card. Only considers enabled alarms.
final nextAlarmProvider = Provider<Alarm?>((ref) {
  final alarms = ref.watch(alarmsProvider).where((a) => a.isEnabled).toList();
  if (alarms.isEmpty) return null;

  DateTime bestTime = DateTime(9999);
  Alarm? best;
  final now = DateTime.now();

  for (final alarm in alarms) {
    for (final slot in alarm.daySlots) {
      var candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (slot == 0) {
        if (candidate.isBefore(now)) candidate = candidate.add(const Duration(days: 1));
      } else {
        while (candidate.weekday != slot || candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
      }
      if (candidate.isBefore(bestTime)) {
        bestTime = candidate;
        best = alarm;
      }
    }
  }
  return best;
});
