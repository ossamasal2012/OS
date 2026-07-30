import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/core/utils/shared_enums.dart';
import 'package:life_os/features/tasks/models/task.dart';
import 'package:life_os/features/tasks/providers/tasks_provider.dart';

class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  late Task _task;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _categoryController;
  final _newSubtaskController = TextEditingController();
  bool get _isNew => widget.taskId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.taskId == null ? null : _find(widget.taskId!);
    _task = existing ?? Task(title: '');
    _titleController = TextEditingController(text: _task.title);
    _notesController = TextEditingController(text: _task.notes);
    _categoryController = TextEditingController(text: _task.category ?? '');
  }

  Task? _find(String id) {
    for (final t in ref.read(tasksProvider)) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    _task = _task.copyWith(
      title: _titleController.text.trim(),
      notes: _notesController.text,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
    );
    if (_isNew) {
      ref.read(tasksProvider.notifier).add(_task);
    } else {
      ref.read(tasksProvider.notifier).update(_task);
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickDueDateTime() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _task.dueDateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_task.dueDateTime ?? now),
    );
    if (time == null) return;
    setState(() {
      _task = _task.copyWith(
        dueDateTime: DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
    });
    if (mounted && _task.dueDateTime != null) {
      _showSnack(l10n.tasksDueDateSet);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _task = _task.copyWith(subtasks: [..._task.subtasks, SubTask(title: text)]);
    });
    _newSubtaskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.tasksNewTask : l10n.tasksEditTask),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                ref.read(tasksProvider.notifier).delete(_task);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(hintText: l10n.tasksTitleHint),
            autofocus: _isNew,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.tasksNotesHint),
          ),
          const SizedBox(height: 20),

          Text(l10n.tasksPriority, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: Priority.values.map((p) {
              final selected = _task.priority == p;
              return GestureDetector(
                onTap: () => setState(() => _task = _task.copyWith(priority: p)),
                child: Opacity(
                  opacity: selected ? 1 : 0.45,
                  child: PriorityBadge(priority: p),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text(l10n.tasksDueDate, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDateTime,
                  icon: const Icon(Icons.event_rounded),
                  label: Text(
                    _task.dueDateTime == null
                        ? l10n.tasksPickDueDate
                        : DateTimeUtils.formatDateTime(_task.dueDateTime!, locale),
                  ),
                ),
              ),
              if (_task.dueDateTime != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(
                    () => _task = _task.copyWith(clearDueDateTime: true),
                  ),
                ),
            ],
          ),
          if (_task.dueDateTime != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tasksReminder),
              value: _task.reminderEnabled,
              onChanged: (v) => setState(() => _task = _task.copyWith(reminderEnabled: v)),
            ),
          const SizedBox(height: 10),

          Text(l10n.tasksRecurrence, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SegmentedButton<Recurrence>(
            segments: [
              ButtonSegment(value: Recurrence.none, label: Text(l10n.recurrenceNone)),
              ButtonSegment(value: Recurrence.daily, label: Text(l10n.recurrenceDaily)),
              ButtonSegment(value: Recurrence.weekly, label: Text(l10n.recurrenceWeekly)),
              ButtonSegment(value: Recurrence.monthly, label: Text(l10n.recurrenceMonthly)),
            ],
            selected: {_task.recurrence},
            onSelectionChanged: (s) => setState(() => _task = _task.copyWith(recurrence: s.first)),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: l10n.tasksCategoryHint,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: 24),

          Text(l10n.tasksSubtasks, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ..._task.subtasks.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: s.isDone,
                onChanged: (_) => setState(() {
                  _task = _task.copyWith(
                    subtasks: _task.subtasks
                        .map((x) => x.id == s.id ? x.copyWith(isDone: !x.isDone) : x)
                        .toList(),
                  );
                }),
              ),
              title: Text(
                s.title,
                style: TextStyle(decoration: s.isDone ? TextDecoration.lineThrough : null),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() {
                  _task = _task.copyWith(
                    subtasks: _task.subtasks.where((x) => x.id != s.id).toList(),
                  );
                }),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newSubtaskController,
                  decoration: InputDecoration(hintText: l10n.tasksAddSubtask),
                  onSubmitted: (_) => _addSubtask(),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle_rounded), onPressed: _addSubtask),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _save,
            child: Text(l10n.commonSave),
          ),
        ),
      ),
    );
  }
}
