import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/utils/enum_hive_adapter.dart';
import 'package:life_os/core/utils/shared_enums.dart';

import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/tasks/models/task.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/grades/models/course.dart';
import 'package:life_os/features/pomodoro/models/pomodoro_session.dart';

/// Everything Hive-related happens through this class. `init()` is called
/// exactly once, from `main()`, before `runApp()` — every box is open and
/// every adapter registered by the time the widget tree builds, so every
/// feature's ViewModel can read its box *synchronously* in its constructor
/// with no FutureBuilder/loading-state ceremony required anywhere in the UI.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Enums (register before the models that use them).
    Hive.registerAdapter(EnumHiveAdapter<Priority>(HiveTypeIds.priorityEnum, Priority.values));
    Hive.registerAdapter(
      EnumHiveAdapter<Recurrence>(HiveTypeIds.recurrenceEnum, Recurrence.values),
    );
    Hive.registerAdapter(
      EnumHiveAdapter<AlarmSoundSource>(
        HiveTypeIds.alarmSoundSourceEnum,
        AlarmSoundSource.values,
      ),
    );

    // Models.
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(SubTaskAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(AlarmAdapter());
    Hive.registerAdapter(CourseAdapter());
    Hive.registerAdapter(PomodoroSessionAdapter());

    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox<Note>(HiveBoxes.notes),
      Hive.openBox<Task>(HiveBoxes.tasks),
      Hive.openBox<Goal>(HiveBoxes.goals),
      Hive.openBox<Alarm>(HiveBoxes.alarms),
      Hive.openBox<Course>(HiveBoxes.courses),
      Hive.openBox<PomodoroSession>(HiveBoxes.pomodoroSessions),
    ]);

    _initialized = true;
  }

  /// Typed convenience getters so feature repositories don't repeat
  /// `Hive.box<Note>(HiveBoxes.notes)` everywhere.
  static Box get settings => Hive.box(HiveBoxes.settings);
  static Box<Note> get notes => Hive.box<Note>(HiveBoxes.notes);
  static Box<Task> get tasks => Hive.box<Task>(HiveBoxes.tasks);
  static Box<Goal> get goals => Hive.box<Goal>(HiveBoxes.goals);
  static Box<Alarm> get alarms => Hive.box<Alarm>(HiveBoxes.alarms);
  static Box<Course> get courses => Hive.box<Course>(HiveBoxes.courses);
  static Box<PomodoroSession> get pomodoroSessions =>
      Hive.box<PomodoroSession>(HiveBoxes.pomodoroSessions);
}
