import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/workout_log.dart';

class WorkoutRepository {
  final File? overrideFile;

  WorkoutRepository({this.overrideFile});

  Future<File> get _localFile async {
    if (overrideFile != null) return overrideFile!;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/workout_logs.json');
  }

  Future<List<WorkoutLog>> loadWorkoutLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonList = jsonDecode(contents) as List<dynamic>;
        return jsonList
            .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWorkoutLogs(List<WorkoutLog> logs) async {
    final file = await _localFile;
    final jsonList = logs.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await file.writeAsString(jsonString);
  }

  Future<void> addWorkoutLog(WorkoutLog log) async {
    final logs = await loadWorkoutLogs();
    logs.add(log);
    await saveWorkoutLogs(logs);
  }
}
