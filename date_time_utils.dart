import 'package:intl/intl.dart';

/// Small, dependency-light date/time helpers shared by many features
/// (Notes, Tasks, Goals, Alarms, Stopwatch, Countdown, Statistics…). Keeping
/// these in one place means every screen formats dates the same way.
class DateTimeUtils {
  DateTimeUtils._();

  /// e.g. "27 يوليو 2026" when [locale] is 'ar', "July 27, 2026" for 'en'.
  static String formatFullDate(DateTime date, String locale) {
    final pattern = locale == 'ar' ? 'd MMMM y' : 'MMMM d, y';
    return DateFormat(pattern, locale).format(date);
  }

  /// e.g. "الاثنين" / "Monday".
  static String formatWeekday(DateTime date, String locale) {
    return DateFormat('EEEE', locale).format(date);
  }

  /// e.g. "٠٩:٤١ ص" / "9:41 AM" — always 12-hour with am/pm marker since
  /// that's the convention most alarm/clock apps use.
  static String formatTime(DateTime date, String locale) {
    return DateFormat('hh:mm a', locale).format(date);
  }

  static String formatDateTime(DateTime date, String locale) {
    return '${formatFullDate(date, locale)} • ${formatTime(date, locale)}';
  }

  /// A short relative label: "اليوم", "غدًا", "أمس", otherwise the date.
  static String formatRelativeDay(
    DateTime date,
    String locale, {
    required String todayLabel,
    required String tomorrowLabel,
    required String yesterdayLabel,
  }) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return todayLabel;
    if (diff == 1) return tomorrowLabel;
    if (diff == -1) return yesterdayLabel;
    return formatFullDate(date, locale);
  }

  /// Formats a [Duration] as "HH:MM:SS" (or "MM:SS" when under an hour),
  /// using Western digits regardless of locale since this is used inside
  /// monospace timer displays (stopwatch, countdown, pomodoro).
  static String formatDurationClock(Duration duration) {
    final isNegative = duration.isNegative;
    final d = isNegative ? -duration : duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    if (h > 0) {
      buffer.write('${h.toString().padLeft(2, '0')}:');
    }
    buffer.write('${m.toString().padLeft(2, '0')}:');
    buffer.write(s.toString().padLeft(2, '0'));
    return buffer.toString();
  }

  /// "2ي 03:15:09" style breakdown used by the countdown-timer builder UI
  /// (days / hours / minutes / seconds all shown separately).
  static (int days, int hours, int minutes, int seconds) breakDown(
    Duration duration,
  ) {
    final total = duration.isNegative ? Duration.zero : duration;
    final days = total.inDays;
    final hours = total.inHours.remainder(24);
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    return (days, hours, minutes, seconds);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Combines a date-only [DateTime] with a time-only [DateTime] into one.
  static DateTime combine(DateTime date, DateTime time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
