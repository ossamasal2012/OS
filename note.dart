import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/theme/app_colors.dart';
import 'package:life_os/core/utils/id_generator.dart';

/// A note. `body` has no length cap — Hive stores arbitrary-length strings
/// happily, so "unlimited note length" is true by construction rather than
/// something the app has to special-case.
class Note extends HiveObject {
  Note({
    String? id,
    required this.title,
    required this.body,
    int? colorValue,
    this.category,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? IdGenerator.newId(),
        colorValue = colorValue ?? AppColors.brass.value,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  String body;
  int colorValue;
  String? category;
  bool isPinned;
  bool isArchived;
  bool isDeleted;
  final DateTime createdAt;
  DateTime updatedAt;

  Note copyWith({
    String? title,
    String? body,
    int? colorValue,
    String? category,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'colorValue': colorValue,
        'category': category,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        colorValue: json['colorValue'] as int?,
        category: json['category'] as String?,
        isPinned: json['isPinned'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = HiveTypeIds.note;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      colorValue: fields[3] as int,
      category: fields[4] as String?,
      isPinned: fields[5] as bool,
      isArchived: fields[6] as bool,
      isDeleted: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.isArchived)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }
}
