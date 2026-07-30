import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/utils/id_generator.dart';
import 'package:life_os/core/utils/shared_enums.dart';

class Goal extends HiveObject {
  Goal({
    String? id,
    required this.name,
    this.description = '',
    this.category,
    this.priority = Priority.medium,
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.isCompleted = false,
    this.isArchived = false,
    DateTime? createdAt,
  })  : id = id ?? IdGenerator.newId(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String description;
  String? category;
  Priority priority;
  DateTime? startDate;
  DateTime? endDate;
  double progress; // 0.0 .. 1.0
  bool isCompleted;
  bool isArchived;
  final DateTime createdAt;

  Goal copyWith({
    String? name,
    String? description,
    String? category,
    Priority? priority,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    double? progress,
    bool? isCompleted,
    bool? isArchived,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'priority': priority.name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'progress': progress,
        'isCompleted': isCompleted,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String?,
        priority: Priority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => Priority.medium,
        ),
        startDate:
            json['startDate'] == null ? null : DateTime.tryParse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'] as String),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = HiveTypeIds.goal;

  @override
  Goal read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Goal(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String? ?? '',
      category: fields[3] as String?,
      priority: fields[4] as Priority,
      startDate: fields[5] as DateTime?,
      endDate: fields[6] as DateTime?,
      progress: (fields[7] as num).toDouble(),
      isCompleted: fields[8] as bool,
      isArchived: fields[9] as bool,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.isArchived)
      ..writeByte(10)
      ..write(obj.createdAt);
  }
}
