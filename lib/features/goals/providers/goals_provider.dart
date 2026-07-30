import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/goals/repositories/goal_repository.dart';

class GoalsNotifier extends Notifier<List<Goal>> {
  final GoalRepository _repo = GoalRepositoryImpl();

  @override
  List<Goal> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> add(Goal goal) async {
    final result = await _repo.add(goal);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> update(Goal goal) async {
    final result = await _repo.update(goal);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> delete(String id) async {
    final result = await _repo.delete(id);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> setProgress(Goal goal, double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    return update(goal.copyWith(progress: clamped, isCompleted: clamped >= 1.0));
  }

  Future<void> setArchived(Goal goal, bool archived) => update(goal.copyWith(isArchived: archived));
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final goals =
      ref.watch(goalsProvider).where((g) => !g.isArchived && !g.isCompleted).toList();
  goals.sort((a, b) {
    if (a.endDate == null && b.endDate == null) return b.createdAt.compareTo(a.createdAt);
    if (a.endDate == null) return 1;
    if (b.endDate == null) return -1;
    return a.endDate!.compareTo(b.endDate!);
  });
  return goals;
});

final completedGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).where((g) => g.isCompleted && !g.isArchived).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final archivedGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).where((g) => g.isArchived).toList();
});

final goalCategoriesProvider = Provider<List<String>>((ref) {
  final cats = ref
      .watch(goalsProvider)
      .map((g) => g.category)
      .whereType<String>()
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList();
  cats.sort();
  return cats;
});
