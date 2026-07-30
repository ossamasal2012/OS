import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/notes/pages/note_editor_page.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';

class NotesArchivePage extends ConsumerWidget {
  const NotesArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedNotesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesArchive)),
      body: archived.isEmpty
          ? EmptyStateView(icon: Icons.archive_outlined, title: l10n.notesArchiveEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: archived.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final note = archived[i];
                return Card(
                  child: ListTile(
                    title: Text(note.title.isEmpty ? l10n.notesUntitled : note.title),
                    subtitle: Text(
                      note.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: note.id)),
                    ),
                    trailing: IconButton(
                      tooltip: l10n.notesUnarchive,
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () =>
                          ref.read(notesProvider.notifier).setArchived(note, false),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
