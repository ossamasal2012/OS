import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/utils/id_generator.dart';

/// One completed focus session — logged purely for the Statistics screen
/// (study hours over time). Breaks are not logged; only finished work
/// sessions count toward "study hours".
class PomodoroSession extends HiveObject {
  PomodoroSession({String? id, required this.minutes, DateTime? completedAt})
      : id = id ?? IdGenerator.newId(),
        completedAt = completedAt ?? DateTime.now();

  final String id;
  final int minutes;
  final DateTime completedAt;
}

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = HiveTypeIds.pomodoroSession;

  @override
  PomodoroSession read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return PomodoroSession(
      id: fields[0] as String,
      minutes: fields[1] as int,
      completedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.minutes)
      ..writeByte(2)
      ..write(obj.completedAt);
  }
}
