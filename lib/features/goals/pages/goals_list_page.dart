import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/goals/pages/goal_editor_page.dart';
import 'package:life_os/features/goals/providers/goals_provider.dart';
import 'package:life_os/features/goals/widgets/goal_card.dart';

class GoalsListPage extends ConsumerStatefulWidget {
  const GoalsListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends ConsumerState<GoalsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = ref.watch(activeGoalsProvider);
    final completed = ref.watch(completedGoalsProvider);
    final archived = ref.watch(archivedGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.goalsTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: '${l10n.goalsActive} (${active.length})'),
            Tab(text: '${l10n.goalsCompleted} (${completed.length})'),
            Tab(text: '${l10n.goalsArchived} (${archived.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const GoalEditorPage())),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalListView(goals: active, emptyTitle: l10n.goalsEmptyActive),
          _GoalListView(goals: completed, emptyTitle: l10n.goalsEmptyCompleted),
          _GoalListView(goals: archived, emptyTitle: l10n.goalsEmptyArchived),
        ],
      ),
    );
  }
}

class _GoalListView extends StatelessWidget {
  const _GoalListView({required this.goals, required this.emptyTitle});

  final List<Goal> goals;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return EmptyStateView(icon: Icons.flag_outlined, title: emptyTitle);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final goal = goals[i];
        return GoalCard(
          goal: goal,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GoalEditorPage(goalId: goal.id)),
          ),
        );
      },
    );
  }
}
