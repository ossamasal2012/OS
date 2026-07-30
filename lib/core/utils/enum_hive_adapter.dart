import 'package:hive_ce/hive_ce.dart';

/// A single reusable [TypeAdapter] for *any* enum type, registered once per
/// enum with its own [typeId]. Values are stored by their `.name` string
/// rather than their index, so adding a new case anywhere but the very end
/// of an enum — or reordering cases — can't quietly turn an old saved value
/// into a different one.
///
/// Usage:
/// ```dart
/// enum Priority { low, medium, high }
/// Hive.registerAdapter(EnumHiveAdapter<Priority>(HiveTypeIds.priorityEnum, Priority.values));
/// ```
class EnumHiveAdapter<T extends Enum> extends TypeAdapter<T> {
  EnumHiveAdapter(this.typeId, this.values);

  @override
  final int typeId;

  final List<T> values;

  @override
  T read(BinaryReader reader) {
    final name = reader.readString();
    return values.firstWhere(
      (v) => v.name == name,
      orElse: () => values.first,
    );
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.writeString(obj.name);
  }
}
