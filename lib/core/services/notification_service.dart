import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// The three kinds of notification a personal-productivity app actually
/// needs, kept as separate Android channels so the user can mute/tune them
/// independently from system settings:
enum NotifKind { alarm, reminder, timer }

/// What the user tapped: a notification action button's id (`'snooze'` /
/// `'dismiss'`, or null for a plain tap on the notification body) plus
/// whatever payload string was attached when it was scheduled.
class NotificationTapEvent {
  const NotificationTapEvent({this.actionId, this.payload});
  final String? actionId;
  final String? payload;
}

/// Everything notification- and alarm-scheduling related goes through this
/// one service. See README.md → "How alarms actually work on Android" for
/// the full explanation of the design below (exact alarms, per-sound
/// channels, and why boot persistence needs zero extra code here).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Fired whenever the user taps a notification or one of its action
  /// buttons (snooze/dismiss). main.dart listens to this to navigate to the
  /// right screen and/or act on which button was pressed.
  static final ValueNotifier<NotificationTapEvent?> lastTap = ValueNotifier(null);

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      // `getLocalTimezone()` has returned either a plain String or a
      // TimezoneInfo object (with an `.identifier` field) across different
      // flutter_timezone versions. Resolving it dynamically keeps this
      // working either way instead of hard-depending on one exact version.
      final dynamic raw = await FlutterTimezone.getLocalTimezone();
      final String id = raw is String ? raw : (raw.identifier as String);
      tz.setLocalLocation(tz.getLocation(id));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        lastTap.value = NotificationTapEvent(
          actionId: response.actionId,
          payload: response.payload,
        );
      },
    );

    await _createBaseChannels();
    _initialized = true;
  }

  // ---------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------

  /// POST_NOTIFICATIONS (Android 13+). Call this once, e.g. from the
  /// dashboard on first launch — without it, nothing below will show.
  static Future<bool> requestNotificationPermission() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted;
  }

  /// SCHEDULE_EXACT_ALARM (Android 12+). Needed for alarms/timers to fire
  /// at the *exact* second rather than being batched by the OS. Safe to
  /// call repeatedly; it's a no-op if already granted.
  static Future<bool> requestExactAlarmPermission() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await impl?.requestExactAlarmsPermission();
    return granted ?? false;
  }

  static Future<bool> hasExactAlarmPermission() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await impl?.canScheduleExactNotifications() ?? false;
  }

  // ---------------------------------------------------------------------
  // Channels
  // ---------------------------------------------------------------------

  static Future<void> _createBaseChannels() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return;

    await impl.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminders_channel',
        'التذكيرات',
        description: 'تذكيرات المهام والأهداف',
        importance: Importance.high,
      ),
    );
    await impl.createNotificationChannel(
      const AndroidNotificationChannel(
        'timers_channel',
        'المؤقتات',
        description: 'انتهاء العد التنازلي وجلسات بومودورو',
        importance: Importance.high,
      ),
    );
    // Alarm channels are created lazily per sound — see
    // `_ensureAlarmChannel` — because Android locks a channel's sound in at
    // creation time, so every distinct alarm tone needs its own channel id.
  }

  /// Deterministic channel id for a given alarm sound so the *same* sound
  /// always reuses the *same* channel (instead of accumulating a new system
  /// channel every time an alarm is saved).
  static String channelIdForBuiltInTone(String toneKey) =>
      'alarm_channel_builtin_$toneKey';

  static String channelIdForCustomSound(String pathOrUri) =>
      'alarm_channel_custom_${pathOrUri.hashCode & 0x7fffffff}';

  static Future<void> _ensureAlarmChannel(
    String channelId,
    AndroidNotificationSound sound,
  ) async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'المنبهات',
        description: 'قناة صوت المنبه',
        importance: Importance.max,
        sound: sound,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Alarms (repeat by day-of-week; "no day selected" == every day)
  // ---------------------------------------------------------------------

  /// One deterministic, stable notification id per (alarm, day-slot) pair.
  /// [daySlot] is 0 for "every day" (no specific weekdays chosen) or
  /// DateTime.monday..DateTime.sunday (1..7) for a specific weekday.
  static int alarmNotificationId(String alarmId, int daySlot) {
    final base = alarmId.hashCode & 0x00FFFFFF; // <= ~16.7M, keeps *10 safe
    return base * 10 + daySlot;
  }

  /// Schedules one Android alarm-style notification for [time] (today or
  /// the next occurrence of that time), repeating via
  /// [DateTimeComponents.time] (every day) when [daySlot] is 0, or
  /// [DateTimeComponents.dayOfWeekAndTime] for a specific weekday.
  static Future<void> scheduleAlarmOccurrence({
    required String alarmId,
    required int daySlot, // 0 = daily, 1..7 = Mon..Sun
    required DateTime time,
    required String label,
    required AndroidNotificationSound sound,
    required String channelId,
    required String payload,
  }) async {
    await _ensureAlarmChannel(channelId, sound);

    final tzTime = _nextInstanceForDaySlot(time, daySlot);

    await _plugin.zonedSchedule(
      alarmNotificationId(alarmId, daySlot),
      label.isEmpty ? 'المنبه' : label,
      'اضغط لإيقاف المنبه أو الغفوة',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'المنبهات',
          channelDescription: 'قناة صوت المنبه',
          importance: Importance.max,
          priority: Priority.max,
          sound: sound,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('snooze', 'غفوة', cancelNotification: true),
            AndroidNotificationAction('dismiss', 'إيقاف', cancelNotification: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: daySlot == 0
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  static tz.TZDateTime _nextInstanceForDaySlot(DateTime time, int daySlot) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (daySlot == 0) {
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }
    while (scheduled.weekday != daySlot || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAlarmOccurrence(String alarmId, int daySlot) {
    return _plugin.cancel(alarmNotificationId(alarmId, daySlot));
  }

  static Future<void> cancelAllOccurrencesForAlarm(
    String alarmId,
    List<int> daySlots,
  ) async {
    final slots = daySlots.isEmpty ? [0] : daySlots;
    for (final s in slots) {
      await cancelAlarmOccurrence(alarmId, s);
    }
  }

  /// Snoozes by posting a one-off reminder [minutes] from now on the same
  /// channel/sound, without disturbing the alarm's regular recurring
  /// schedule.
  static Future<void> snoozeAlarm({
    required String alarmId,
    required int minutes,
    required String label,
    required AndroidNotificationSound sound,
    required String channelId,
    required String payload,
  }) async {
    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _plugin.zonedSchedule(
      // Snooze uses a distinct id space so it never collides with / cancels
      // the alarm's normal recurring schedule.
      1900000000 + (alarmId.hashCode & 0x00FFFFFF),
      label.isEmpty ? 'غفوة' : label,
      'حان وقت الاستيقاظ',
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'المنبهات',
          importance: Importance.max,
          priority: Priority.max,
          sound: sound,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('dismiss', 'إيقاف', cancelNotification: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------
  // Simple one-off notifications (task/goal reminders, timer completion)
  // ---------------------------------------------------------------------

  static Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required NotifKind kind,
    String? payload,
  }) async {
    final channelId = kind == NotifKind.reminder ? 'reminders_channel' : 'timers_channel';
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'reminders_channel' ? 'التذكيرات' : 'المؤقتات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required NotifKind kind,
    String? payload,
  }) async {
    final channelId = kind == NotifKind.reminder ? 'reminders_channel' : 'timers_channel';
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'reminders_channel' ? 'التذكيرات' : 'المؤقتات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();
}
