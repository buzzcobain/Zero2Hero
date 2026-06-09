class ExerciseLog {
  final String exerciseId;
  final double weightKg;
  final List<int> reps; // e.g. [10, 10, 10] or [12, 12, 10]

  ExerciseLog({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exercise_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      reps: List<int>.from(json['reps'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'weight_kg': weightKg,
      'reps': reps,
    };
  }
}

class WorkoutLog {
  final String id;
  final DateTime date;
  final String workoutType; // 'Workout A' or 'Workout B'
  final List<ExerciseLog> exercises;
  final double durationMinutes;
  final double caloriesBurned;

  WorkoutLog({
    required this.id,
    required this.date,
    required this.workoutType,
    required this.exercises,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      workoutType: json['workout_type'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      durationMinutes: (json['duration_minutes'] as num).toDouble(),
      caloriesBurned: (json['calories_burned'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'workout_type': workoutType,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
    };
  }
}
