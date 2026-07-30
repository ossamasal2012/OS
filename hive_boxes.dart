/// Every Hive box name used by the app, in one place. Nothing else in the
/// codebase should write a box name as a raw string literal — always
/// reference a constant from here. This makes renaming a box, or auditing
/// exactly what gets persisted, a one-file job.
class HiveBoxes {
  HiveBoxes._();

  static const String settings = 'box_settings';
  static const String notes = 'box_notes';
  static const String tasks = 'box_tasks';
  static const String goals = 'box_goals';
  static const String alarms = 'box_alarms';
  static const String courses = 'box_courses';
  static const String pomodoroSessions = 'box_pomodoro_sessions';

  /// All boxes that must be opened once at startup, before runApp(). Keep
  /// this list in sync with the constants above — main.dart iterates it.
  static const List<String> all = [
    settings,
    notes,
    tasks,
    goals,
    alarms,
    courses,
    pomodoroSessions,
  ];
}

/// Keys used inside the single-map [HiveBoxes.settings] box (it stores loose
/// key/value settings rather than a list of objects, so it doesn't need a
/// model class or adapter).
class SettingsKeys {
  SettingsKeys._();

  static const String themeMode = 'theme_mode'; // system|light|dark
  static const String useMaterialYou = 'use_material_you'; // bool
  static const String seedColorValue = 'seed_color_value'; // int (Color.value)
  static const String fontScale = 'font_scale'; // double
  static const String localeCode = 'locale_code'; // 'ar' | 'en'
  static const String stopwatchState = 'stopwatch_state'; // json string
  static const String countdownState = 'countdown_state'; // json string
  static const String pomodoroState = 'pomodoro_state'; // json string
  static const String pomodoroWorkMinutes = 'pomodoro_work_minutes';
  static const String pomodoroBreakMinutes = 'pomodoro_break_minutes';
  static const String pomodoroLongBreakMinutes = 'pomodoro_long_break_minutes';
  static const String pomodoroSessionsUntilLongBreak =
      'pomodoro_sessions_until_long_break';
  static const String customRingtonePath = 'custom_ringtone_path';
  static const String onboardingComplete = 'onboarding_complete';
}
