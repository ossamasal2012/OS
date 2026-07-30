import 'package:uuid/uuid.dart';

/// Thin wrapper around the `uuid` package so the rest of the codebase never
/// imports it directly or repeats `const Uuid()` everywhere.
class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  /// A new random (v4) unique id, suitable as a Hive key / entity id.
  static String newId() => _uuid.v4();
}

