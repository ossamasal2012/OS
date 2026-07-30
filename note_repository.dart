import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/result.dart';
import 'package:life_os/features/notes/models/note.dart';

/// What the presentation layer is allowed to know about: a small set of
/// intention-revealing operations. It does NOT know these are backed by
/// Hive — swapping storage later (e.g. to sqlite) only ever touches
/// [NoteRepositoryImpl].
abstract class NoteRepository {
  List<Note> getAll();
  Future<Result<Note>> add(Note note);
  Future<Result<Note>> update(Note note);
  Future<Result<void>> hardDelete(String id);
}

class NoteRepositoryImpl implements NoteRepository {
  @override
  List<Note> getAll() => HiveService.notes.values.toList();

  @override
  Future<Result<Note>> add(Note note) async {
    try {
      await HiveService.notes.put(note.id, note);
      return Success(note);
    } catch (e) {
      return FailureResult(Failure('failed to add note', exception: e));
    }
  }

  @override
  Future<Result<Note>> update(Note note) async {
    try {
      await HiveService.notes.put(note.id, note);
      return Success(note);
    } catch (e) {
      return FailureResult(Failure('failed to update note', exception: e));
    }
  }

  @override
  Future<Result<void>> hardDelete(String id) async {
    try {
      await HiveService.notes.delete(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure('failed to delete note', exception: e));
    }
  }
}
