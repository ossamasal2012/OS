import 'package:flutter/material.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/alarms/pages/alarms_list_page.dart';
import 'package:life_os/features/calculator/pages/calculator_page.dart';
import 'package:life_os/features/countdown_timer/pages/countdown_timer_page.dart';
import 'package:life_os/features/grades/pages/grades_page.dart';
import 'package:life_os/features/pomodoro/pages/pomodoro_page.dart';
import 'package:life_os/features/search/pages/search_page.dart';
import 'package:life_os/features/settings/pages/settings_page.dart';
import 'package:life_os/features/statistics/pages/statistics_page.dart';
import 'package:life_os/features/stopwatch/pages/stopwatch_page.dart';
import 'package:life_os/features/unit_converter/pages/unit_converter_page.dart';

class _HubItem {
  const _HubItem(this.icon, this.label, this.builder);
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

class MoreHubPage extends StatelessWidget {
  const MoreHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final sections = <String, List<_HubItem>>{
      l10n.hubSectionTime: [
        _HubItem(Icons.alarm_rounded, l10n.alarmsTitle, (_) => const AlarmsListPage()),
        _HubItem(Icons.timer_outlined, l10n.stopwatchTitle, (_) => const StopwatchPage()),
        _HubItem(Icons.hourglass_bottom_rounded, l10n.countdownTitle, (_) => const CountdownTimerPage()),
      ],
      l10n.hubSectionStudy: [
        _HubItem(Icons.self_improvement_rounded, l10n.pomodoroTitle, (_) => const PomodoroPage()),
        _HubItem(Icons.school_rounded, l10n.gradesTitle, (_) => const GradesPage()),
      ],
      l10n.hubSectionTools: [
        _HubItem(Icons.calculate_outlined, l10n.calculatorTitle, (_) => const CalculatorPage()),
        _HubItem(Icons.straighten_rounded, l10n.converterTitle, (_) => const UnitConverterPage()),
      ],
      l10n.hubSectionInsights: [
        _HubItem(Icons.bar_chart_rounded, l10n.statisticsTitle, (_) => const StatisticsPage()),
        _HubItem(Icons.search_rounded, l10n.searchTitle, (_) => const SearchPage()),
      ],
      l10n.hubSectionSystem: [
        _HubItem(Icons.settings_outlined, l10n.settingsTitle, (_) => const SettingsPage()),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: sections.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: entry.value.map((item) {
                    return Material(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: item.builder)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, color: theme.colorScheme.primary, size: 26),
                              const SizedBox(height: 8),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
