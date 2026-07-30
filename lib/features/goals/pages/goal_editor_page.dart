import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/utils/shared_enums.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/goals/providers/goals_provider.dart';

class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  late Goal _goal;
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;
  bool get _isNew => widget.goalId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.goalId == null ? null : _find(widget.goalId!);
    _goal = existing ?? Goal(name: '');
    _nameController = TextEditingController(text: _goal.name);
    _descController = TextEditingController(text: _goal.description);
    _categoryController = TextEditingController(text: _goal.category ?? '');
  }

  Goal? _find(String id) {
    for (final g in ref.read(goalsProvider)) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    _goal = _goal.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
    );
    if (_isNew) {
      ref.read(goalsProvider.notifier).add(_goal);
    } else {
      ref.read(goalsProvider.notifier).update(_goal);
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _goal.startDate : _goal.endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    setState(() {
      _goal = isStart ? _goal.copyWith(startDate: picked) : _goal.copyWith(endDate: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.goalsNewGoal : l10n.goalsEditGoal),
        actions: [
          if (!_isNew) ...[
            IconButton(
              tooltip: l10n.goalsArchive,
              icon: Icon(_goal.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
              onPressed: () {
                ref.read(goalsProvider.notifier).setArchived(_goal, !_goal.isArchived);
                Navigator.of(context).pop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                ref.read(goalsProvider.notifier).delete(_goal.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(hintText: l10n.goalsNameHint),
            autofocus: _isNew,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.goalsDescriptionHint),
          ),
          const SizedBox(height: 20),

          Text(l10n.tasksPriority, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: Priority.values.map((p) {
              final selected = _goal.priority == p;
              return GestureDetector(
                onTap: () => setState(() => _goal = _goal.copyWith(priority: p)),
                child: Opacity(opacity: selected ? 1 : 0.45, child: PriorityBadge(priority: p)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text(l10n.goalsProgress, style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _goal.progress,
                  onChanged: (v) => setState(() => _goal = _goal.copyWith(
                        progress: v,
                        isCompleted: v >= 1.0,
                      )),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text('${(_goal.progress * 100).round()}%', textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    _goal.startDate == null
                        ? l10n.goalsStartDate
                        : DateTimeUtils.formatFullDate(_goal.startDate!, locale),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(
                    _goal.endDate == null
                        ? l10n.goalsDeadline
                        : DateTimeUtils.formatFullDate(_goal.endDate!, locale),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: l10n.tasksCategoryHint,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
        ),
      ),
    );
  }
}
