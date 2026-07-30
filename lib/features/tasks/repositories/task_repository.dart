import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/result.dart';
import 'package:life_os/features/tasks/models/task.dart';

abstract class TaskRepository {
  List<Task> getAll();
  Future<Result<Task>> add(Task task);
  Future<Result<Task>> update(Task task);
  Future<Result<void>> delete(String id);
}

class TaskRepositoryImpl implements TaskRepository {
  @override
  List<Task> getAll() => HiveService.tasks.values.toList();

  @override
  Future<Result<Task>> add(Task task) async {
    try {
      await HiveService.tasks.put(task.id, task);
      return Success(task);
    } catch (e) {
      return FailureResult(Failure('failed to add task', exception: e));
    }
  }

  @override
  Future<Result<Task>> update(Task task) async {
    try {
      await HiveService.tasks.put(task.id, task);
      return Success(task);
    } catch (e) {
      return FailureResult(Failure('failed to update task', exception: e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await HiveService.tasks.delete(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure('failed to delete task', exception: e));
    }
  }
}
