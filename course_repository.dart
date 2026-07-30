import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/utils/result.dart';
import 'package:life_os/features/grades/models/course.dart';

abstract class CourseRepository {
  List<Course> getAll();
  Future<Result<Course>> add(Course course);
  Future<Result<Course>> update(Course course);
  Future<Result<void>> delete(String id);
}

class CourseRepositoryImpl implements CourseRepository {
  @override
  List<Course> getAll() => HiveService.courses.values.toList();

  @override
  Future<Result<Course>> add(Course course) async {
    try {
      await HiveService.courses.put(course.id, course);
      return Success(course);
    } catch (e) {
      return FailureResult(Failure('failed to add course', exception: e));
    }
  }

  @override
  Future<Result<Course>> update(Course course) async {
    try {
      await HiveService.courses.put(course.id, course);
      return Success(course);
    } catch (e) {
      return FailureResult(Failure('failed to update course', exception: e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await HiveService.courses.delete(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure('failed to delete course', exception: e));
    }
  }
}
