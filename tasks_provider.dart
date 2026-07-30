import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/features/tasks/models/task.dart';
import 'package:life_os/features/tasks/repositories/task_repository.dart';

class TasksNotifier extends Notifier<List<Task>> {
  final TaskRepository _repo = TaskRepositoryImpl();

  @override
  List<Task> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> _syncReminder(Task task) async {
    await NotificationService.cancel(task.reminderNotificationId);
    if (task.reminderEnabled &&
        !task.isCompleted &&
        task.dueDateTime != null &&
        task.dueDateTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleOneOff(
        id: task.reminderNotificationId,
        title: task.title,
        body: 'موعد استحقاق المهمة الآن',
        when: task.dueDateTime!,
        kind: NotifKind.reminder,
        payload: 'task:${task.id}',
      );
    }
  }

  Future<void> add(Task task) async {
    final result = await _repo.add(task);
    result.fold((t) {
      _syncReminder(t);
      _refresh();
    }, (_) => null);
  }

  Future<void> update(Task task) async {
    final result = await _repo.update(task);
    result.fold((t) {
      _syncReminder(t);
      _refresh();
    }, (_) => null);
  }

  Future<void> delete(Task task) async {
    await NotificationService.cancel(task.reminderNotificationId);
    final result = await _repo.delete(task.id);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> toggleComplete(Task task) async {
    if (!task.isCompleted && task.recurrence.name != 'none') {
      // Recurring + just finished -> roll forward instead of just marking done.
      await update(task.nextOccurrence());
      return;
    }
    await update(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> toggleSubtask(Task task, String subtaskId) async {
    final updated = task.subtasks
        .map((s) => s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s)
        .toList();
    await update(task.copyWith(subtasks: updated));
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

final activeTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).where((t) => !t.isCompleted).toList();
  tasks.sort((a, b) {
    if (a.dueDateTime == null && b.dueDateTime == null) return 0;
    if (a.dueDateTime == null) return 1;
    if (b.dueDateTime == null) return -1;
    return a.dueDateTime!.compareTo(b.dueDateTime!);
  });
  return tasks;
});

final completedTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(tasksProvider).where((t) => t.isCompleted).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final taskCategoriesProvider = Provider<List<String>>((ref) {
  final cats = ref
      .watch(tasksProvider)
      .map((t) => t.category)
      .whereType<String>()
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList();
  cats.sort();
  return cats;
});

/// Today's completion ratio, used by the Dashboard.
final todayTaskProgressProvider = Provider<double>((ref) {
  final tasks = ref.watch(tasksProvider);
  final now = DateTime.now();
  final todays = tasks.where((t) {
    final d = t.dueDateTime;
    return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
  if (todays.isEmpty) return 0;
  final done = todays.where((t) => t.isCompleted).length;
  return done / todays.length;
});
