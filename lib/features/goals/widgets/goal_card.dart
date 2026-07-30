import 'package:flutter/material.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/features/goals/models/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: goal.progress,
                      strokeWidth: 5,
                      backgroundColor: scheme.primary.withOpacity(0.12),
                    ),
                    Text('${(goal.progress * 100).round()}%', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityBadge(priority: goal.priority, compact: true),
                        if (goal.endDate != null)
                          Text(
                            '${l10n.goalsDeadline}: ${DateTimeUtils.formatFullDate(goal.endDate!, locale)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                          ),
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
