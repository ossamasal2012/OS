import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/utils/id_generator.dart';

/// Standard 4.0-scale letter grades. Kept as one small table so changing
/// the scale later (or adding a percentage-based mode) touches one place.
const Map<String, double> letterGradePoints = {
  'A+': 4.0, 'A': 4.0, 'A-': 3.7,
  'B+': 3.3, 'B': 3.0, 'B-': 2.7,
  'C+': 2.3, 'C': 2.0, 'C-': 1.7,
  'D+': 1.3, 'D': 1.0, 'D-': 0.7,
  'F': 0.0,
};

class Course extends HiveObject {
  Course({
    String? id,
    required this.name,
    this.creditHours = 3,
    this.letterGrade = 'A',
    this.semester,
    DateTime? createdAt,
  })  : id = id ?? IdGenerator.newId(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  double creditHours;
  String letterGrade;
  String? semester;
  final DateTime createdAt;

  double get gradePoints => letterGradePoints[letterGrade] ?? 0;
  double get qualityPoints => gradePoints * creditHours;

  Course copyWith({
    String? name,
    double? creditHours,
    String? letterGrade,
    String? semester,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      creditHours: creditHours ?? this.creditHours,
      letterGrade: letterGrade ?? this.letterGrade,
      semester: semester ?? this.semester,
      createdAt: createdAt,
    );
  }
}

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = HiveTypeIds.course;

  @override
  Course read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Course(
      id: fields[0] as String,
      name: fields[1] as String,
      creditHours: (fields[2] as num).toDouble(),
      letterGrade: fields[3] as String,
      semester: fields[4] as String?,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.creditHours)
      ..writeByte(3)
      ..write(obj.letterGrade)
      ..writeByte(4)
      ..write(obj.semester)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
