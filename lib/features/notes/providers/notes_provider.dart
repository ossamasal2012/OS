import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/notes/repositories/note_repository.dart';

class NotesNotifier extends Notifier<List<Note>> {
  final NoteRepository _repo = NoteRepositoryImpl();

  @override
  List<Note> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> add(Note note) async {
    final result = await _repo.add(note);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> update(Note note) async {
    final result = await _repo.update(note);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> togglePin(Note note) => update(note.copyWith(isPinned: !note.isPinned));

  Future<void> setArchived(Note note, bool archived) =>
      update(note.copyWith(isArchived: archived));

  /// Soft delete — moves to Trash instead of removing immediately, so an
  /// accidental delete is always recoverable.
  Future<void> moveToTrash(Note note) =>
      update(note.copyWith(isDeleted: true, isArchived: false));

  Future<void> restoreFromTrash(Note note) => update(note.copyWith(isDeleted: false));

  Future<void> hardDelete(String id) async {
    final result = await _repo.hardDelete(id);
    result.fold((_) => _refresh(), (_) => null);
  }

  Future<void> emptyTrash() async {
    final trashed = state.where((n) => n.isDeleted).toList();
    for (final n in trashed) {
      await _repo.hardDelete(n.id);
    }
    _refresh();
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

List<Note> _sortedByPinThenUpdated(Iterable<Note> notes) {
  final list = notes.toList();
  list.sort((a, b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return list;
}

/// Everything that's neither archived nor trashed — the main Notes list.
final activeNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).where((n) => !n.isDeleted && !n.isArchived);
  return _sortedByPinThenUpdated(notes);
});

final archivedNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).where((n) => n.isArchived && !n.isDeleted);
  return _sortedByPinThenUpdated(notes);
});

final trashedNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).where((n) => n.isDeleted);
  final list = notes.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return list;
});

/// Every distinct category currently in use, for the category filter chips.
final noteCategoriesProvider = Provider<List<String>>((ref) {
  final cats = ref
      .watch(notesProvider)
      .map((n) => n.category)
      .whereType<String>()
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList();
  cats.sort();
  return cats;
});
