import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/stat_pill.dart';
import 'package:life_os/features/goals/providers/goals_provider.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';
import 'package:life_os/features/tasks/providers/tasks_provider.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    final goals = ref.watch(goalsProvider);
    final notes = ref.watch(activeNotesProvider);
    final sessions = HiveService.pomodoroSessions.values.toList();

    final totalStudyMinutes = sessions.fold<int>(0, (sum, s) => sum + s.minutes);
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final completedGoals = goals.where((g) => g.isCompleted).length;

    // Tasks completed per day, last 7 days.
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final dayCounts = last7.map((day) {
      return tasks.where((t) {
        if (!t.isCompleted || t.dueDateTime == null) return false;
        final d = t.dueDateTime!;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    }).toList();
    final maxCount = (dayCounts.isEmpty ? 0 : dayCounts.reduce((a, b) => a > b ? a : b))
        .clamp(1, double.infinity)
        .toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatPill(icon: Icons.check_circle_outline_rounded, value: '$completedTasks', label: l10n.statisticsTasksDone),
              StatPill(icon: Icons.flag_outlined, value: '$completedGoals', label: l10n.statisticsGoalsDone),
              StatPill(icon: Icons.sticky_note_2_outlined, value: '${notes.length}', label: l10n.statisticsActiveNotes),
              StatPill(
                icon: Icons.timer_outlined,
                value: (totalStudyMinutes / 60).toStringAsFixed(1),
                label: l10n.statisticsStudyHours,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(l10n.statisticsTasksLast7Days, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxCount + 1,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= last7.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${last7[i].day}/${last7[i].month}', style: theme.textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dayCounts[i].toDouble(),
                        color: theme.colorScheme.primary,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.statisticsGoalsProgress, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ...goals.where((g) => !g.isArchived).take(5).map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: g.progress, minHeight: 8),
                      ),
                    ],
                  ),
                ),
              ),
          if (goals.isEmpty)
            Text(l10n.statisticsNoGoalsYet, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
