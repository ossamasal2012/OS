import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/alarms/pages/alarm_editor_page.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/goals/pages/goal_editor_page.dart';
import 'package:life_os/features/goals/providers/goals_provider.dart';
import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/notes/pages/note_editor_page.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';
import 'package:life_os/features/tasks/models/task.dart';
import 'package:life_os/features/tasks/pages/task_editor_page.dart';
import 'package:life_os/features/tasks/providers/tasks_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;

    final notes = hasQuery
        ? ref
            .watch(notesProvider)
            .where((n) => !n.isDeleted && (n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)))
            .toList()
        : <Note>[];
    final tasks = hasQuery
        ? ref.watch(tasksProvider).where((t) => t.title.toLowerCase().contains(q)).toList()
        : <Task>[];
    final goals = hasQuery
        ? ref.watch(goalsProvider).where((g) => g.name.toLowerCase().contains(q)).toList()
        : <Goal>[];
    final alarms = hasQuery
        ? ref.watch(alarmsProvider).where((a) => a.label.toLowerCase().contains(q)).toList()
        : <Alarm>[];

    final totalResults = notes.length + tasks.length + goals.length + alarms.length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: !hasQuery
          ? EmptyStateView(icon: Icons.search_rounded, title: l10n.searchPrompt)
          : totalResults == 0
              ? EmptyStateView(icon: Icons.search_off_rounded, title: l10n.searchNoResults)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (notes.isNotEmpty) ...[
                      _SectionLabel(l10n.notesTitle),
                      ...notes.map(
                        (n) => ListTile(
                          leading: const Icon(Icons.sticky_note_2_outlined),
                          title: Text(n.title.isEmpty ? l10n.notesUntitled : n.title),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: n.id))),
                        ),
                      ),
                    ],
                    if (tasks.isNotEmpty) ...[
                      _SectionLabel(l10n.tasksTitle),
                      ...tasks.map(
                        (t) => ListTile(
                          leading: const Icon(Icons.check_circle_outline_rounded),
                          title: Text(t.title),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => TaskEditorPage(taskId: t.id))),
                        ),
                      ),
                    ],
                    if (goals.isNotEmpty) ...[
                      _SectionLabel(l10n.goalsTitle),
                      ...goals.map(
                        (g) => ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(g.name),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => GoalEditorPage(goalId: g.id))),
                        ),
                      ),
                    ],
                    if (alarms.isNotEmpty) ...[
                      _SectionLabel(l10n.alarmsTitle),
                      ...alarms.map(
                        (a) => ListTile(
                          leading: const Icon(Icons.alarm_outlined),
                          title: Text(a.label),
                          subtitle: Text(
                            '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => AlarmEditorPage(alarmId: a.id))),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
