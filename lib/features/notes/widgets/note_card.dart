import 'package:flutter/material.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/notes/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = Color(note.colorValue);
    final locale = Localizations.localeOf(context).languageCode;

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? context.l10n.notesUntitled : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (note.isPinned)
                    Icon(Icons.push_pin_rounded, size: 16, color: scheme.primary),
                ],
              ),
              if (note.body.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (note.category != null && note.category!.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(note.category!, style: theme.textTheme.labelSmall),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    DateTimeUtils.formatRelativeDay(
                      note.updatedAt,
                      locale,
                      todayLabel: context.l10n.today,
                      tomorrowLabel: context.l10n.tomorrow,
                      yesterdayLabel: context.l10n.yesterday,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.5),
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
