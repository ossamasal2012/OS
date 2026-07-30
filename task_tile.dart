import 'package:flutter/material.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/features/tasks/models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  bool get _isOverdue =>
      !task.isCompleted && task.dueDateTime != null && task.dueDateTime!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggle(),
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? scheme.onSurface.withOpacity(0.5) : null,
                      ),
                    ),
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: task.completionRatio,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}'
                        ' ${l10n.tasksSubtasks}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityBadge(priority: task.priority, compact: true),
                        if (task.dueDateTime != null)
                          _Chip(
                            icon: Icons.schedule_rounded,
                            label:
                                '${DateTimeUtils.formatRelativeDay(task.dueDateTime!, locale, todayLabel: l10n.today, tomorrowLabel: l10n.tomorrow, yesterdayLabel: l10n.yesterday)} '
                                '${DateTimeUtils.formatTime(task.dueDateTime!, locale)}',
                            color: _isOverdue ? scheme.error : null,
                          ),
                        if (task.category != null && task.category!.isNotEmpty)
                          _Chip(icon: Icons.label_outline_rounded, label: task.category!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c)),
      ],
    );
  }
}
