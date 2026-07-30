/// Every Hive `typeId` used anywhere in the app, in one place, so a new
/// model can never accidentally reuse an id that's already taken. Valid
/// range for Hive is 0–223. Leave gaps between groups so a feature can grow
/// a little without renumbering everything else.
///
/// IMPORTANT: once the app has real user data on a device, an id must keep
/// pointing at the same class forever (that's *how* Hive knows what to
/// decode a stored object as) — so treat this file as append-only.
library;

class HiveTypeIds {
  HiveTypeIds._();

  // Models
  static const int note = 0;
  static const int task = 1;
  static const int subTask = 2;
  static const int goal = 3;
  static const int alarm = 4;
  static const int course = 5;
  static const int pomodoroSession = 6;

  // Enums (stored via the generic EnumHiveAdapter<T>)
  static const int priorityEnum = 50;
  static const int recurrenceEnum = 51;
  static const int alarmSoundSourceEnum = 52;
  static const int goalStatusEnum = 53;
}
