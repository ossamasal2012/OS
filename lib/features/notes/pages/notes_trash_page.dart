import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';

class NotesTrashPage extends ConsumerWidget {
  const NotesTrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trashed = ref.watch(trashedNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notesTrash),
        actions: [
          if (trashed.isNotEmpty)
            TextButton(
              onPressed: () => _confirmEmptyTrash(context, ref),
              child: Text(l10n.notesEmptyTrash),
            ),
        ],
      ),
      body: trashed.isEmpty
          ? EmptyStateView(icon: Icons.delete_outline_rounded, title: l10n.notesTrashEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trashed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final note = trashed[i];
                return Card(
                  child: ListTile(
                    title: Text(note.title.isEmpty ? l10n.notesUntitled : note.title),
                    subtitle: Text(
                      note.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.notesRestore,
                          icon: const Icon(Icons.restore_rounded),
                          onPressed: () =>
                              ref.read(notesProvider.notifier).restoreFromTrash(note),
                        ),
                        IconButton(
                          tooltip: l10n.commonDelete,
                          icon: const Icon(Icons.delete_forever_rounded),
                          onPressed: () =>
                              ref.read(notesProvider.notifier).hardDelete(note.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notesEmptyTrash),
        content: Text(l10n.notesEmptyTrashConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notesProvider.notifier).emptyTrash();
              Navigator.pop(ctx);
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}
