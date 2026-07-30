import 'package:hive_ce/hive_ce.dart';
import 'package:life_os/core/constants/builtin_tones.dart';
import 'package:life_os/core/constants/hive_type_ids.dart';
import 'package:life_os/core/theme/app_colors.dart';
import 'package:life_os/core/utils/id_generator.dart';
import 'package:life_os/core/utils/shared_enums.dart';

class Alarm extends HiveObject {
  Alarm({
    String? id,
    this.label = '',
    required this.hour,
    required this.minute,
    List<int>? daysOfWeek,
    this.isEnabled = true,
    int? colorValue,
    this.soundSource = AlarmSoundSource.builtIn,
    String? soundValue,
    this.vibrate = true,
    this.snoozeMinutes = 5,
    this.snoozeMaxCount = 3,
    this.autoDismissMinutes = 10,
    DateTime? createdAt,
  })  : id = id ?? IdGenerator.newId(),
        daysOfWeek = daysOfWeek ?? [],
        colorValue = colorValue ?? AppColors.brass.value,
        soundValue = soundValue ?? BuiltInTones.defaultKey,
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String label;
  int hour; // 0-23
  int minute; // 0-59

  /// DateTime.monday(1)..DateTime.sunday(7). Empty means "every day".
  List<int> daysOfWeek;
  bool isEnabled;
  int colorValue;
  AlarmSoundSource soundSource;

  /// Built-in tone key, OR a device file path/content URI, depending on
  /// [soundSource].
  String soundValue;
  bool vibrate;
  int snoozeMinutes;

  /// -1 means unlimited snoozes.
  int snoozeMaxCount;

  /// 0 means "never auto-dismiss" (rings/shows until the user acts).
  int autoDismissMinutes;
  final DateTime createdAt;

  /// The "day slots" this alarm actually needs scheduled: `[0]` for every
  /// day, or one entry per selected weekday.
  List<int> get daySlots => daysOfWeek.isEmpty ? [0] : daysOfWeek;

  DateTime timeToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Alarm copyWith({
    String? label,
    int? hour,
    int? minute,
    List<int>? daysOfWeek,
    bool? isEnabled,
    int? colorValue,
    AlarmSoundSource? soundSource,
    String? soundValue,
    bool? vibrate,
    int? snoozeMinutes,
    int? snoozeMaxCount,
    int? autoDismissMinutes,
  }) {
    return Alarm(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      colorValue: colorValue ?? this.colorValue,
      soundSource: soundSource ?? this.soundSource,
      soundValue: soundValue ?? this.soundValue,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeMaxCount: snoozeMaxCount ?? this.snoozeMaxCount,
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'daysOfWeek': daysOfWeek,
        'isEnabled': isEnabled,
        'colorValue': colorValue,
        'soundSource': soundSource.name,
        'soundValue': soundValue,
        'vibrate': vibrate,
        'snoozeMinutes': snoozeMinutes,
        'snoozeMaxCount': snoozeMaxCount,
        'autoDismissMinutes': autoDismissMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        hour: json['hour'] as int? ?? 7,
        minute: json['minute'] as int? ?? 0,
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
        isEnabled: json['isEnabled'] as bool? ?? true,
        colorValue: json['colorValue'] as int?,
        soundSource: AlarmSoundSource.values.firstWhere(
          (s) => s.name == json['soundSource'],
          orElse: () => AlarmSoundSource.builtIn,
        ),
        soundValue: json['soundValue'] as String?,
        vibrate: json['vibrate'] as bool? ?? true,
        snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
        snoozeMaxCount: json['snoozeMaxCount'] as int? ?? 3,
        autoDismissMinutes: json['autoDismissMinutes'] as int? ?? 10,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  final int typeId = HiveTypeIds.alarm;

  @override
  Alarm read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Alarm(
      id: fields[0] as String,
      label: fields[1] as String,
      hour: fields[2] as int,
      minute: fields[3] as int,
      daysOfWeek: (fields[4] as List).cast<int>(),
      isEnabled: fields[5] as bool,
      colorValue: fields[6] as int,
      soundSource: fields[7] as AlarmSoundSource,
      soundValue: fields[8] as String,
      vibrate: fields[9] as bool,
      snoozeMinutes: fields[10] as int,
      snoozeMaxCount: fields[11] as int,
      autoDismissMinutes: fields[12] as int? ?? 10,
      createdAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.daysOfWeek)
      ..writeByte(5)
      ..write(obj.isEnabled)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.soundSource)
      ..writeByte(8)
      ..write(obj.soundValue)
      ..writeByte(9)
      ..write(obj.vibrate)
      ..writeByte(10)
      ..write(obj.snoozeMinutes)
      ..writeByte(11)
      ..write(obj.snoozeMaxCount)
      ..writeByte(12)
      ..write(obj.autoDismissMinutes)
      ..writeByte(13)
      ..write(obj.createdAt);
  }
}
