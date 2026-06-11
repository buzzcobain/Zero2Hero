import 'package:flutter_test/flutter_test.dart';
import 'package:zero2hero/data/models/user_profile.dart';
import 'package:zero2hero/data/models/workout_definitions.dart';
import 'package:zero2hero/data/models/workout_log.dart';
import 'package:zero2hero/domain/progressive_roadmap_engine.dart';

void main() {
  group('Additional Coverage Tests', () {
    test('WorkoutDefinitions serialization', () {
      final jsonEx = {
        'id': 'ex1',
        'name': 'Test Ex',
        'focus': 'Test Focus',
        'rest_seconds': 30,
      };
      final ex = ExerciseDefinition.fromJson(jsonEx);
      expect(ex.id, 'ex1');
      expect(ex.name, 'Test Ex');
      expect(ex.focus, 'Test Focus');
      expect(ex.restSeconds, 30);
      expect(ex.toJson(), jsonEx);

      final jsonWorkout = {
        'title': 'Test Workout',
        'exercises': [jsonEx],
      };
      final workout = WorkoutDefinition.fromJson(jsonWorkout);
      expect(workout.title, 'Test Workout');
      expect(workout.exercises.first.id, 'ex1');
      expect(workout.toJson(), jsonWorkout);

      final workoutA = WorkoutRoutines.getById('Workout A');
      expect(workoutA.title, WorkoutRoutines.workoutA.title);
      expect(WorkoutRoutines.getById('A').title, WorkoutRoutines.workoutA.title);
      expect(WorkoutRoutines.getById('Chest & Arms').title, WorkoutRoutines.workoutA.title);

      final workoutB = WorkoutRoutines.getById('Workout B');
      expect(workoutB.title, WorkoutRoutines.workoutB.title);
      expect(WorkoutRoutines.getById('other').title, WorkoutRoutines.workoutB.title);
    });

    test('UserProfile & UserData copyWith & serialization', () {
      final profile = UserProfile(
        heightCm: 175,
        currentWeightKg: 70.0,
        useWeightVest: false,
        weightVestKg: 0.0,
      );

      final copy = profile.copyWith(heightCm: 180, useWeightVest: true);
      expect(copy.heightCm, 180);
      expect(copy.useWeightVest, isTrue);

      final weights = ExerciseWeights(
        floorPress: 8.0,
        militaryPress: 8.0,
        supinatingCurl: 8.0,
        crossHammer: 8.0,
        chairKickback: 8.0,
        uprightRow: 8.0,
        shrug: 8.0,
        rearFlye: 8.0,
        gobletSquat: 8.0,
        romanianDeadlift: 8.0,
        splitSquat: 8.0,
        calfRaise: 8.0,
      );

      // Verify all getWeightForExercise cases
      expect(weights.getWeightForExercise('floor_press'), 8.0);
      expect(weights.getWeightForExercise('military_press'), 8.0);
      expect(weights.getWeightForExercise('supinating_curl'), 8.0);
      expect(weights.getWeightForExercise('cross_hammer'), 8.0);
      expect(weights.getWeightForExercise('chair_kickback'), 8.0);
      expect(weights.getWeightForExercise('upright_row'), 8.0);
      expect(weights.getWeightForExercise('shrug'), 8.0);
      expect(weights.getWeightForExercise('rear_flye'), 8.0);
      expect(weights.getWeightForExercise('unknown'), 8.0);

      // Verify all copyWithExercise cases
      expect(weights.copyWithExercise('floor_press', 10.0).floorPress, 10.0);
      expect(weights.copyWithExercise('military_press', 10.0).militaryPress, 10.0);
      expect(weights.copyWithExercise('supinating_curl', 10.0).supinatingCurl, 10.0);
      expect(weights.copyWithExercise('cross_hammer', 10.0).crossHammer, 10.0);
      expect(weights.copyWithExercise('chair_kickback', 10.0).chairKickback, 10.0);
      expect(weights.copyWithExercise('upright_row', 10.0).uprightRow, 10.0);
      expect(weights.copyWithExercise('shrug', 10.0).shrug, 10.0);
      expect(weights.copyWithExercise('rear_flye', 10.0).rearFlye, 10.0);
      expect(weights.copyWithExercise('unknown', 10.0).floorPress, 8.0);

      final userData = UserData(profile: profile, weights: weights);
      final json = userData.toJson();
      final decoded = UserData.fromJson(json);

      expect(decoded.profile.heightCm, 175);
      expect(decoded.weights.floorPress, 8.0);
    });

    test('ProgressiveRoadmapEngine negative week offset and stage boundary edge cases', () {
      final DateTime baselineDate = DateTime(2026, 6, 1);
      final log = WorkoutLog(
        id: '1',
        date: baselineDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Past date -> weeksElapsed is negative or 0
      final target = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log],
        currentDate: baselineDate.subtract(const Duration(days: 10)),
      );

      expect(target.stage, RoadmapStage.stage1);
      expect(target.weightKg, 8.0);
      expect(target.targetReps, 10);
    });

    test('ProgressiveRoadmapEngine Stage 3 and 4 combinations', () {
      final DateTime baseDate = DateTime(2026, 6, 1);
      
      // Log 1: Week 1 (Stage 1)
      final log1 = WorkoutLog(
        id: '1',
        date: baseDate,
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Log 2: Week 3 (Stage 2)
      final log2 = WorkoutLog(
        id: '2',
        date: baseDate.add(const Duration(days: 14)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Log 3: Week 4 (Stage 2)
      final log3 = WorkoutLog(
        id: '3',
        date: baseDate.add(const Duration(days: 21)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 8.0, reps: [15, 15, 15]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Calculate Target at Week 5 (Stage 3)
      final targetS3 = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1, log2, log3],
        currentDate: baseDate.add(const Duration(days: 28)),
      );
      expect(targetS3.stage, RoadmapStage.stage3);
      expect(targetS3.weightKg, 9.0);
      expect(targetS3.targetReps, 10);

      // Log 4: Week 5 (Stage 3)
      final log4 = WorkoutLog(
        id: '4',
        date: baseDate.add(const Duration(days: 29)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 9.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Log 5: Week 6 (Stage 3)
      final log5 = WorkoutLog(
        id: '5',
        date: baseDate.add(const Duration(days: 35)),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 9.0, reps: [12, 12, 12]),
        ],
        durationMinutes: 30.0,
        caloriesBurned: 100.0,
      );

      // Calculate Target at Week 9 (Stage 4)
      final targetS4 = ProgressiveRoadmapEngine.calculateTarget(
        exerciseId: 'floor_press',
        initialWeight: 8.0,
        history: [log1, log2, log3, log4, log5],
        currentDate: baseDate.add(const Duration(days: 56)),
      );
      expect(targetS4.stage, RoadmapStage.stage4);
      expect(targetS4.weightKg, 10.0);
      expect(targetS4.targetReps, 10);
    });
  });
}
