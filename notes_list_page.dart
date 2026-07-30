import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/notes/pages/note_editor_page.dart';
import 'package:life_os/features/notes/pages/notes_archive_page.dart';
import 'package:life_os/features/notes/pages/notes_trash_page.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';
import 'package:life_os/features/notes/widgets/note_card.dart';

class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> _filtered(List<Note> notes) {
    var result = notes;
    if (_categoryFilter != null) {
      result = result.where((n) => n.category == _categoryFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result
          .where((n) => n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = _filtered(ref.watch(activeNotesProvider));
    final categories = ref.watch(noteCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.notesTitle),
        actions: [
          IconButton(
            tooltip: l10n.notesArchive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotesArchivePage())),
          ),
          IconButton(
            tooltip: l10n.notesTrash,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotesTrashPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NoteEditorPage())),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n.notesSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(l10n.commonAll),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                  ),
                  ...categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _categoryFilter == c,
                        onSelected: (_) => setState(
                          () => _categoryFilter = _categoryFilter == c ? null : c,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: notes.isEmpty
                ? EmptyStateView(
                    icon: Icons.sticky_note_2_outlined,
                    title: l10n.notesEmptyTitle,
                    message: l10n.notesEmptyMessage,
                    actionLabel: l10n.notesNewNote,
                    onAction: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const NoteEditorPage())),
                  )
                : MasonryGrid(notes: notes),
          ),
        ],
      ),
    );
  }
}

/// A simple two-column masonry-style layout (no extra package needed) —
/// notes naturally vary in height, so a plain GridView would leave awkward
/// gaps.
class MasonryGrid extends StatelessWidget {
  const MasonryGrid({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];
    for (var i = 0; i < notes.length; i++) {
      (i.isEven ? left : right).add(notes[i]);
    }

    Widget column(List<Note> items) => Expanded(
          child: Column(
            children: items
                .map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoteCard(
                      note: n,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: n.id)),
                      ),
                      onLongPress: () => _showQuickActions(context, n),
                    ),
                  ),
                )
                .toList(),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [column(left), const SizedBox(width: 12), column(right)],
      ),
    );
  }

  void _showQuickActions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _NoteQuickActionsSheet(note: note),
    );
  }
}

class _NoteQuickActionsSheet extends ConsumerWidget {
  const _NoteQuickActionsSheet({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(note.isPinned ? l10n.notesUnpin : l10n.notesPin),
            onTap: () {
              ref.read(notesProvider.notifier).togglePin(note);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(l10n.notesArchive),
            onTap: () {
              ref.read(notesProvider.notifier).setArchived(note, true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(l10n.notesMoveToTrash),
            onTap: () {
              ref.read(notesProvider.notifier).moveToTrash(note);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
