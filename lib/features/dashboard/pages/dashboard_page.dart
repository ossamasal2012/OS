import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/glass_card.dart';
import 'package:life_os/features/alarms/pages/alarms_list_page.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';
import 'package:life_os/features/calculator/pages/calculator_page.dart';
import 'package:life_os/features/countdown_timer/pages/countdown_timer_page.dart';
import 'package:life_os/features/goals/pages/goals_list_page.dart';
import 'package:life_os/features/goals/providers/goals_provider.dart';
import 'package:life_os/features/notes/pages/notes_list_page.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';
import 'package:life_os/features/pomodoro/pages/pomodoro_page.dart';
import 'package:life_os/features/search/pages/search_page.dart';
import 'package:life_os/features/stopwatch/pages/stopwatch_page.dart';
import 'package:life_os/features/tasks/pages/tasks_list_page.dart';
import 'package:life_os/features/tasks/providers/tasks_provider.dart';
import 'package:life_os/features/unit_converter/pages/unit_converter_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late final Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _greeting(BuildContext context) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.dashboardGreetingNight;
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 17) return l10n.dashboardGreetingAfternoon;
    return l10n.dashboardGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    final taskProgress = ref.watch(todayTaskProgressProvider);
    final nextAlarm = ref.watch(nextAlarmProvider);
    final goalsCount = ref.watch(activeGoalsProvider).length;
    final notesCount = ref.watch(activeNotesProvider).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('Life OS'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchPage())),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(_greeting(context), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${DateTimeUtils.formatWeekday(now, locale)} • ${DateTimeUtils.formatFullDate(now, locale)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 20),

                _HeroClockCard(now: now, locale: locale, taskProgress: taskProgress),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(
                      icon: Icons.alarm_rounded,
                      label: l10n.dashboardNextAlarm,
                      value: nextAlarm == null
                          ? l10n.dashboardNoAlarm
                          : '${nextAlarm.hour.toString().padLeft(2, '0')}:${nextAlarm.minute.toString().padLeft(2, '0')}',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const AlarmsListPage())),
                    ),
                    _StatCard(
                      icon: Icons.flag_rounded,
                      label: l10n.dashboardActiveGoals,
                      value: '$goalsCount',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const GoalsListPage())),
                    ),
                    _StatCard(
                      icon: Icons.sticky_note_2_rounded,
                      label: l10n.dashboardNotes,
                      value: '$notesCount',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const NotesListPage())),
                    ),
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: l10n.dashboardTasksToday,
                      value: '${(taskProgress * 100).round()}%',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const TasksListPage())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(l10n.dashboardQuickActions, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      icon: Icons.timer_outlined,
                      label: l10n.stopwatchTitle,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const StopwatchPage())),
                    ),
                    _QuickAction(
                      icon: Icons.hourglass_bottom_rounded,
                      label: l10n.countdownTitle,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CountdownTimerPage())),
                    ),
                    _QuickAction(
                      icon: Icons.calculate_outlined,
                      label: l10n.calculatorTitle,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CalculatorPage())),
                    ),
                    _QuickAction(
                      icon: Icons.straighten_rounded,
                      label: l10n.converterTitle,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const UnitConverterPage())),
                    ),
                    _QuickAction(
                      icon: Icons.self_improvement_rounded,
                      label: l10n.pomodoroTitle,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const PomodoroPage())),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroClockCard extends StatelessWidget {
  const _HeroClockCard({required this.now, required this.locale, required this.taskProgress});
  final DateTime now;
  final String locale;
  final double taskProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: GlassCard(
        borderRadius: 24,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeUtils.formatTime(now, locale),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.dashboardTasksToday}: ${(taskProgress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: taskProgress,
                strokeWidth: 6,
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const Spacer(),
              Text(value, style: theme.textTheme.titleLarge),
              Text(label, style: theme.textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
