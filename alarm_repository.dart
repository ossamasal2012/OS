import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/result.dart';
import 'package:life_os/features/alarms/models/alarm.dart';

abstract class AlarmRepository {
  List<Alarm> getAll();
  Alarm? getById(String id);
  Future<Result<Alarm>> add(Alarm alarm);
  Future<Result<Alarm>> update(Alarm alarm);
  Future<Result<void>> delete(String id);
}

class AlarmRepositoryImpl implements AlarmRepository {
  @override
  List<Alarm> getAll() => HiveService.alarms.values.toList();

  @override
  Alarm? getById(String id) => HiveService.alarms.get(id);

  @override
  Future<Result<Alarm>> add(Alarm alarm) async {
    try {
      await HiveService.alarms.put(alarm.id, alarm);
      return Success(alarm);
    } catch (e) {
      return FailureResult(Failure('failed to add alarm', exception: e));
    }
  }

  @override
  Future<Result<Alarm>> update(Alarm alarm) async {
    try {
      await HiveService.alarms.put(alarm.id, alarm);
      return Success(alarm);
    } catch (e) {
      return FailureResult(Failure('failed to update alarm', exception: e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await HiveService.alarms.delete(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure('failed to delete alarm', exception: e));
    }
  }
}
