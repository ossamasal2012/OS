import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/utils/id_generator.dart';
import 'package:life_os/core/utils/shared_enums.dart';

class SubTask {
  SubTask({String? id, required this.title, this.isDone = false})
      : id = id ?? IdGenerator.newId();

  final String id;
  String title;
  bool isDone;

  SubTask copyWith({String? title, bool? isDone}) =>
      SubTask(id: id, title: title ?? this.title, isDone: isDone ?? this.isDone);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );
}

class SubTaskAdapter extends TypeAdapter<SubTask> {
  @override
  final int typeId = HiveTypeIds.subTask;

  @override
  SubTask read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return SubTask(
      id: fields[0] as String,
      title: fields[1] as String,
      isDone: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isDone);
  }
}

class Task extends HiveObject {
  Task({
    String? id,
    required this.title,
    this.notes = '',
    this.priority = Priority.medium,
    this.dueDateTime,
    this.recurrence = Recurrence.none,
    this.category,
    this.isCompleted = false,
    this.reminderEnabled = true,
    List<SubTask>? subtasks,
    DateTime? createdAt,
  })  : id = id ?? IdGenerator.newId(),
        subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String notes;
  Priority priority;
  DateTime? dueDateTime;
  Recurrence recurrence;
  String? category;
  bool isCompleted;
  bool reminderEnabled;
  List<SubTask> subtasks;
  final DateTime createdAt;

  double get completionRatio {
    if (subtasks.isEmpty) return isCompleted ? 1 : 0;
    final done = subtasks.where((s) => s.isDone).length;
    return done / subtasks.length;
  }

  /// A stable, small-int notification id derived from this task's uuid, so
  /// scheduling/cancelling its reminder never needs a lookup table.
  int get reminderNotificationId => (id.hashCode & 0x7FFFFFFF) % 1000000000;

  Task copyWith({
    String? title,
    String? notes,
    Priority? priority,
    DateTime? dueDateTime,
    bool clearDueDateTime = false,
    Recurrence? recurrence,
    String? category,
    bool? isCompleted,
    bool? reminderEnabled,
    List<SubTask>? subtasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      dueDateTime: clearDueDateTime ? null : (dueDateTime ?? this.dueDateTime),
      recurrence: recurrence ?? this.recurrence,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }

  /// For a recurring task marked complete: the same task, reset to
  /// incomplete, with its due date advanced to the next occurrence.
  Task nextOccurrence() {
    if (recurrence == Recurrence.none || dueDateTime == null) return this;
    DateTime next;
    switch (recurrence) {
      case Recurrence.daily:
        next = dueDateTime!.add(const Duration(days: 1));
        break;
      case Recurrence.weekly:
        next = dueDateTime!.add(const Duration(days: 7));
        break;
      case Recurrence.monthly:
        next = DateTime(dueDateTime!.year, dueDateTime!.month + 1, dueDateTime!.day,
            dueDateTime!.hour, dueDateTime!.minute);
        break;
      case Recurrence.none:
        next = dueDateTime!;
        break;
    }
    return copyWith(
      isCompleted: false,
      dueDateTime: next,
      subtasks: subtasks.map((s) => s.copyWith(isDone: false)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'priority': priority.name,
        'dueDateTime': dueDateTime?.toIso8601String(),
        'recurrence': recurrence.name,
        'category': category,
        'isCompleted': isCompleted,
        'reminderEnabled': reminderEnabled,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        priority: Priority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => Priority.medium,
        ),
        dueDateTime: json['dueDateTime'] == null
            ? null
            : DateTime.tryParse(json['dueDateTime'] as String),
        recurrence: Recurrence.values.firstWhere(
          (r) => r.name == json['recurrence'],
          orElse: () => Recurrence.none,
        ),
        category: json['category'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        subtasks: (json['subtasks'] as List<dynamic>? ?? [])
            .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = HiveTypeIds.task;

  @override
  Task read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String? ?? '',
      priority: fields[3] as Priority,
      dueDateTime: fields[4] as DateTime?,
      recurrence: fields[5] as Recurrence,
      category: fields[6] as String?,
      isCompleted: fields[7] as bool,
      reminderEnabled: fields[8] as bool? ?? true,
      subtasks: (fields[9] as List?)?.cast<SubTask>() ?? [],
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.dueDateTime)
      ..writeByte(5)
      ..write(obj.recurrence)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.reminderEnabled)
      ..writeByte(9)
      ..write(obj.subtasks)
      ..writeByte(10)
      ..write(obj.createdAt);
  }
}
