import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/goals/models/goal.dart';
import 'package:life_os/features/grades/models/course.dart';
import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/tasks/models/task.dart';

/// Exports/imports every user-created record (notes, tasks, goals, alarms,
/// courses) to a single human-readable JSON file. Deliberately excludes
/// transient state (stopwatch/countdown/pomodoro running state) and app
/// settings (theme etc.) — a backup is about *your data*, and re-importing
/// it on a fresh install shouldn't fight with that device's own display
/// preferences.
class BackupService {
  BackupService._();

  static Map<String, dynamic> _buildPayload() {
    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': HiveService.notes.values.map((n) => n.toJson()).toList(),
      'tasks': HiveService.tasks.values.map((t) => t.toJson()).toList(),
      'goals': HiveService.goals.values.map((g) => g.toJson()).toList(),
      'alarms': HiveService.alarms.values.map((a) => a.toJson()).toList(),
      'courses': HiveService.courses.values
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'creditHours': c.creditHours,
                'letterGrade': c.letterGrade,
                'semester': c.semester,
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList(),
    };
  }

  static Future<String> exportToFile() async {
    final payload = _buildPayload();
    final dir = await getTemporaryDirectory();
    final filename = 'life_os_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  static Future<void> exportAndShare() async {
    final path = await exportToFile();
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  /// Returns how many records of each type were imported, or null if the
  /// user cancelled the file picker.
  static Future<Map<String, int>?> pickFileAndImport({required bool merge}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    final content = await File(path).readAsString();
    return importFromJsonString(content, merge: merge);
  }

  static Future<Map<String, int>> importFromJsonString(
    String content, {
    required bool merge,
  }) async {
    final data = jsonDecode(content) as Map<String, dynamic>;
    final counts = <String, int>{};

    if (!merge) {
      await HiveService.notes.clear();
      await HiveService.tasks.clear();
      await HiveService.goals.clear();
      await HiveService.alarms.clear();
      await HiveService.courses.clear();
    }

    final notes = (data['notes'] as List<dynamic>? ?? [])
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final n in notes) {
      await HiveService.notes.put(n.id, n);
    }
    counts['notes'] = notes.length;

    final tasks = (data['tasks'] as List<dynamic>? ?? [])
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final t in tasks) {
      await HiveService.tasks.put(t.id, t);
    }
    counts['tasks'] = tasks.length;

    final goals = (data['goals'] as List<dynamic>? ?? [])
        .map((e) => Goal.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final g in goals) {
      await HiveService.goals.put(g.id, g);
    }
    counts['goals'] = goals.length;

    final alarms = (data['alarms'] as List<dynamic>? ?? [])
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final a in alarms) {
      await HiveService.alarms.put(a.id, a);
    }
    counts['alarms'] = alarms.length;

    final courses = (data['courses'] as List<dynamic>? ?? [])
        .map(
          (e) => Course(
            id: e['id'] as String,
            name: e['name'] as String? ?? '',
            creditHours: (e['creditHours'] as num?)?.toDouble() ?? 3,
            letterGrade: e['letterGrade'] as String? ?? 'A',
            semester: e['semester'] as String?,
            createdAt: DateTime.tryParse(e['createdAt'] as String? ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
    for (final c in courses) {
      await HiveService.courses.put(c.id, c);
    }
    counts['courses'] = courses.length;

    return counts;
  }
}
