import 'package:flutter/material.dart';
import 'package:life_os/core/theme/app_colors.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/utils/shared_enums.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  final Priority priority;
  final bool compact;

  static Color colorFor(Priority p) {
    switch (p) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
    }
  }

  String _label(BuildContext context) {
    switch (priority) {
      case Priority.low:
        return context.l10n.priorityLow;
      case Priority.medium:
        return context.l10n.priorityMedium;
      case Priority.high:
        return context.l10n.priorityHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(priority);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _label(context),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
