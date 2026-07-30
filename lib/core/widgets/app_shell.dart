import 'package:flutter/material.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/dashboard/pages/dashboard_page.dart';
import 'package:life_os/features/dashboard/pages/more_hub_page.dart';
import 'package:life_os/features/goals/pages/goals_list_page.dart';
import 'package:life_os/features/notes/pages/notes_list_page.dart';
import 'package:life_os/features/tasks/pages/tasks_list_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    TasksListPage(embedded: true),
    NotesListPage(embedded: true),
    GoalsListPage(embedded: true),
    MoreHubPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline_rounded),
            selectedIcon: const Icon(Icons.check_circle_rounded),
            label: l10n.navTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sticky_note_2_outlined),
            selectedIcon: const Icon(Icons.sticky_note_2_rounded),
            label: l10n.navNotes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag_rounded),
            label: l10n.navGoals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_rounded),
            selectedIcon: const Icon(Icons.apps_rounded),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
