import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/result.dart';
import 'package:life_os/features/goals/models/goal.dart';

abstract class GoalRepository {
  List<Goal> getAll();
  Future<Result<Goal>> add(Goal goal);
  Future<Result<Goal>> update(Goal goal);
  Future<Result<void>> delete(String id);
}

class GoalRepositoryImpl implements GoalRepository {
  @override
  List<Goal> getAll() => HiveService.goals.values.toList();

  @override
  Future<Result<Goal>> add(Goal goal) async {
    try {
      await HiveService.goals.put(goal.id, goal);
      return Success(goal);
    } catch (e) {
      return FailureResult(Failure('failed to add goal', exception: e));
    }
  }

  @override
  Future<Result<Goal>> update(Goal goal) async {
    try {
      await HiveService.goals.put(goal.id, goal);
      return Success(goal);
    } catch (e) {
      return FailureResult(Failure('failed to update goal', exception: e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await HiveService.goals.delete(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure('failed to delete goal', exception: e));
    }
  }
}
