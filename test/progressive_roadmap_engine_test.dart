import 'package:flutter_test/flutter_test.dart';
import 'package:zero2hero/data/models/workout_log.dart';
import 'package:zero2hero/domain/progressive_roadmap_engine.dart';

void main() {
  group('ProgressiveRoadmapEngine Tests', () {
    final DateTime baselineDate = DateTime(2026, 6, 1);

    test('Stage 1 (Weeks 1-2) - Initial Conditioning', () {
      // Empty history -> week 1 -> Stage 1
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [],
        currentDate: baselineDate,
      );

      expect(target.stage, RoadmapStage.stage1);
      expect(target.weightKg, 8.0);
      expect(target.targetReps, 10);
    });

    test('Stage 2 (Weeks 3-4) - Rep Volume Expansion - Increment reps', () {
      // Create a log in week 1 that hit all sets
      final log1 = WorkoutLog(
        id: '1',
        date: baselineDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 150.0,
      );

      // Current date is 15 days later (week 3 -> Stage 2)
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1],
        currentDate: baselineDate.add(const Duration(days: 15)),
      );

      expect(target.stage, RoadmapStage.stage2);
      expect(target.weightKg, 8.0);
      expect(target.targetReps, 12); // Ticking Set 3 of first session (reps 10) bumps target to 12
    });

    test('Stage 2 - Maxes out at 15 reps', () {
      final log1 = WorkoutLog(
        id: '1',
        date: baselineDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log2 = WorkoutLog(
        id: '2',
        date: baselineDate.add(const Duration(days: 15)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log3 = WorkoutLog(
        id: '3',
        date: baselineDate.add(const Duration(days: 22)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Current date is week 4 (Stage 2)
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1, log2, log3],
        currentDate: baselineDate.add(const Duration(days: 25)),
      );

      expect(target.stage, RoadmapStage.stage2);
      expect(target.weightKg, 8.0);
      expect(target.targetReps, 15);
    });

    test('Stage 3 (Weeks 5-8) - Micro-loading when 3x15 is achieved', () {
      final log1 = WorkoutLog(
        id: '1',
        date: baselineDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log2 = WorkoutLog(
        id: '2',
        date: baselineDate.add(const Duration(days: 15)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log3 = WorkoutLog(
        id: '3',
        date: baselineDate.add(const Duration(days: 22)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log4 = WorkoutLog(
        id: '4',
        date: baselineDate.add(const Duration(days: 25)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [15, 15, 15]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Current date is week 5 (Stage 3)
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1, log2, log3, log4],
        currentDate: baselineDate.add(const Duration(days: 30)),
      );

      expect(target.stage, RoadmapStage.stage3);
      expect(target.weightKg, 9.0); // +1.0kg micro-loading
      expect(target.targetReps, 10); // Resets to 10
    });

    test('Stage 4 (Weeks 9+) - Peak capacity weight bump', () {
      final log1 = WorkoutLog(
        id: '1',
        date: baselineDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log2 = WorkoutLog(
        id: '2',
        date: baselineDate.add(const Duration(days: 15)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log3 = WorkoutLog(
        id: '3',
        date: baselineDate.add(const Duration(days: 20)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log4 = WorkoutLog(
        id: '4',
        date: baselineDate.add(const Duration(days: 25)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [15, 15, 15]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log5 = WorkoutLog(
        id: '5',
        date: baselineDate.add(const Duration(days: 30)), // Week 5 (Stage 3)
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 9.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );
      final log6 = WorkoutLog(
        id: '6',
        date: baselineDate.add(const Duration(days: 35)), // Week 6
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 9.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Current date is week 9 (Stage 4)
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1, log2, log3, log4, log5, log6],
        currentDate: baselineDate.add(const Duration(days: 60)),
      );

      expect(target.stage, RoadmapStage.stage4);
      expect(target.weightKg, 10.0); // +2.0kg total peak capacity
      expect(target.targetReps, 10); // Resets to 10
    });
  });
}
