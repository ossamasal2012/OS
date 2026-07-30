import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/grades/models/course.dart';
import 'package:life_os/features/grades/repositories/course_repository.dart';

class CoursesNotifier extends Notifier<List<Course>> {
  final CourseRepository _repo = CourseRepositoryImpl();

  @override
  List<Course> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> add(Course course) async {
    final r = await _repo.add(course);
    r.fold((_) => _refresh(), (_) => null);
  }

  Future<void> update(Course course) async {
    final r = await _repo.update(course);
    r.fold((_) => _refresh(), (_) => null);
  }

  Future<void> delete(String id) async {
    final r = await _repo.delete(id);
    r.fold((_) => _refresh(), (_) => null);
  }
}

final coursesProvider = NotifierProvider<CoursesNotifier, List<Course>>(CoursesNotifier.new);

final gpaProvider = Provider<double>((ref) {
  final courses = ref.watch(coursesProvider);
  final totalCredits = courses.fold<double>(0, (sum, c) => sum + c.creditHours);
  if (totalCredits == 0) return 0;
  final totalQuality = courses.fold<double>(0, (sum, c) => sum + c.qualityPoints);
  return totalQuality / totalCredits;
});
