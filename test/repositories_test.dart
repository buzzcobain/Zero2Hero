import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero2hero/data/models/user_profile.dart';
import 'package:zero2hero/data/models/workout_log.dart';
import 'package:zero2hero/data/repositories/profile_repository.dart';
import 'package:zero2hero/data/repositories/workout_repository.dart';

void main() {
  group('Repositories Tests', () {
    late Directory tempDir;
    late File tempProfileFile;
    late File tempWorkoutFile;
    late ProfileRepository profileRepo;
    late WorkoutRepository workoutRepo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      tempProfileFile = File('${tempDir.path}/user_profile.json');
      tempWorkoutFile = File('${tempDir.path}/workout_logs.json');
      profileRepo = ProfileRepository(overrideFile: tempProfileFile);
      workoutRepo = WorkoutRepository(overrideFile: tempWorkoutFile);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('ProfileRepository - save and load profile', () async {
      expect(await profileRepo.profileExists(), isFalse);
      expect(await profileRepo.loadProfile(), isNull);

      final profile = UserProfile(
        heightCm: 180,
        currentWeightKg: 75.0,
        useWeightVest: true,
        weightVestKg: 10.0,
      );
      final weights = ExerciseWeights(
        floorPress: 10.0,
        militaryPress: 8.0,
        supinatingCurl: 8.0,
        crossHammer: 8.0,
        chairKickback: 6.0,
        uprightRow: 8.0,
        shrug: 12.0,
        rearFlye: 6.0,
      );
      final userData = UserData(profile: profile, weights: weights);

      await profileRepo.saveProfile(userData);

      expect(await profileRepo.profileExists(), isTrue);

      final loaded = await profileRepo.loadProfile();
      expect(loaded, isNotNull);
      expect(loaded!.profile.heightCm, 180);
      expect(loaded.profile.currentWeightKg, 75.0);
      expect(loaded.profile.useWeightVest, isTrue);
      expect(loaded.profile.weightVestKg, 10.0);
      expect(loaded.weights.floorPress, 10.0);
      expect(loaded.weights.chairKickback, 6.0);
    });

    test('WorkoutRepository - save and load logs', () async {
      var logs = await workoutRepo.loadWorkoutLogs();
      expect(logs, isEmpty);

      final log = WorkoutLog(
        id: 'log123',
        date: DateTime(2026, 6, 1),
        workoutType: 'Workout A',
        exercises: [
          ExerciseLog(exerciseId: 'floor_press', weightKg: 10.0, reps: [10, 10, 10]),
        ],
        durationMinutes: 35.5,
        caloriesBurned: 180.0,
      );

      await workoutRepo.addWorkoutLog(log);

      logs = await workoutRepo.loadWorkoutLogs();
      expect(logs.length, 1);
      expect(logs.first.id, 'log123');
      expect(logs.first.workoutType, 'Workout A');
      expect(logs.first.exercises.first.exerciseId, 'floor_press');
      expect(logs.first.exercises.first.weightKg, 10.0);
      expect(logs.first.exercises.first.reps, [10, 10, 10]);
      expect(logs.first.durationMinutes, 35.5);
      expect(logs.first.caloriesBurned, 180.0);
    });
  });
}
