import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/tasks/models/task.dart';
import 'package:life_os/features/tasks/pages/task_editor_page.dart';
import 'package:life_os/features/tasks/providers/tasks_provider.dart';
import 'package:life_os/features/tasks/widgets/task_tile.dart';

class TasksListPage extends ConsumerStatefulWidget {
  const TasksListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends ConsumerState<TasksListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = ref.watch(activeTasksProvider);
    final completed = ref.watch(completedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.tasksTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '${l10n.tasksActive} (${active.length})'),
            Tab(text: '${l10n.tasksCompleted} (${completed.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TaskEditorPage())),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskListView(
            tasks: active,
            emptyIcon: Icons.check_circle_outline_rounded,
            emptyTitle: l10n.tasksEmptyActive,
          ),
          _TaskListView(
            tasks: completed,
            emptyIcon: Icons.task_alt_rounded,
            emptyTitle: l10n.tasksEmptyCompleted,
          ),
        ],
      ),
    );
  }
}

class _TaskListView extends ConsumerWidget {
  const _TaskListView({required this.tasks, required this.emptyIcon, required this.emptyTitle});

  final List<Task> tasks;
  final IconData emptyIcon;
  final String emptyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return EmptyStateView(icon: emptyIcon, title: emptyTitle);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final task = tasks[i];
        return TaskTile(
          task: task,
          onToggle: () => ref.read(tasksProvider.notifier).toggleComplete(task),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TaskEditorPage(taskId: task.id)),
          ),
        );
      },
    );
  }
}
