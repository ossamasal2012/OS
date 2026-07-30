import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/grades/models/course.dart';
import 'package:life_os/features/grades/providers/grades_provider.dart';

class GradesPage extends ConsumerWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final courses = ref.watch(coursesProvider);
    final gpa = ref.watch(gpaProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gradesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(l10n.gradesGpa, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    gpa.toStringAsFixed(2),
                    style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Text('${l10n.gradesOutOf} 4.00', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          Expanded(
            child: courses.isEmpty
                ? EmptyStateView(icon: Icons.school_outlined, title: l10n.gradesEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = courses[i];
                      return Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.creditHours.toStringAsFixed(1)} ${l10n.gradesCreditHours}'
                            '${c.semester != null ? ' • ${c.semester}' : ''}',
                          ),
                          trailing: Text(c.letterGrade, style: theme.textTheme.titleLarge),
                          onTap: () => _showEditor(context, ref, c),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Course? existing) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final semesterController = TextEditingController(text: existing?.semester ?? '');
    var credits = existing?.creditHours ?? 3.0;
    var grade = existing?.letterGrade ?? 'A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? l10n.gradesAddCourse : l10n.gradesEditCourse,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.gradesCourseName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: semesterController,
                decoration: InputDecoration(labelText: l10n.gradesSemester),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: credits,
                      decoration: InputDecoration(labelText: l10n.gradesCreditHours),
                      items: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0]
                          .map((v) => DropdownMenuItem(value: v, child: Text(v.toStringAsFixed(1))))
                          .toList(),
                      onChanged: (v) => setSheetState(() => credits = v ?? credits),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: grade,
                      decoration: InputDecoration(labelText: l10n.gradesGrade),
                      items: letterGradePoints.keys
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => grade = v ?? grade),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (existing != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () {
                        ref.read(coursesProvider.notifier).delete(existing.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        final course = (existing ?? Course(name: '')).copyWith(
                          name: nameController.text.trim(),
                          creditHours: credits,
                          letterGrade: grade,
                          semester:
                              semesterController.text.trim().isEmpty ? null : semesterController.text.trim(),
                        );
                        if (existing == null) {
                          ref.read(coursesProvider.notifier).add(course);
                        } else {
                          ref.read(coursesProvider.notifier).update(course);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
