import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zero2hero/data/models/user_profile.dart';
import 'package:zero2hero/data/models/workout_definitions.dart';
import 'package:zero2hero/data/models/workout_log.dart';
import 'package:zero2hero/data/repositories/profile_repository.dart';
import 'package:zero2hero/data/repositories/workout_repository.dart';
import 'package:zero2hero/infrastructure/ad_service.dart';
import 'package:zero2hero/presentation/blocs/workout/workout_cubit.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}
class MockAdService extends Mock implements AdServiceInterface {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockWorkoutRepository mockWorkoutRepository;
  late MockAdService mockAdService;
  late WorkoutCubit workoutCubit;

  final profile = UserProfile(
    heightCm: 180,
    currentWeightKg: 80.0,
    useWeightVest: false,
    weightVestKg: 0.0,
  );
  final weights = ExerciseWeights(
    floorPress: 8.0,
    militaryPress: 8.0,
    supinatingCurl: 8.0,
    crossHammer: 8.0,
    chairKickback: 8.0,
    uprightRow: 8.0,
    shrug: 8.0,
    rearFlye: 8.0,
  );
  final userData = UserData(profile: profile, weights: weights);

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockWorkoutRepository = MockWorkoutRepository();
    mockAdService = MockAdService();

    workoutCubit = WorkoutCubit(
      profileRepository: mockProfileRepository,
      workoutRepository: mockWorkoutRepository,
      adService: mockAdService,
    );

    registerFallbackValue(
      WorkoutLog(
        id: '1',
        date: DateTime.now(),
        workoutType: 'Workout A',
        exercises: [],
        durationMinutes: 0.0,
        caloriesBurned: 0.0,
      ),
    );
    registerFallbackValue(
      UserData(profile: profile, weights: weights),
    );

    when(() => mockProfileRepository.loadProfile()).thenAnswer((_) async => userData);
    when(() => mockProfileRepository.saveProfile(any())).thenAnswer((_) async => {});
    when(() => mockWorkoutRepository.loadWorkoutLogs()).thenAnswer((_) async => []);
    when(() => mockWorkoutRepository.addWorkoutLog(any())).thenAnswer((_) async => {});
    when(() => mockAdService.loadInterstitialAd()).thenAnswer((_) async => {});
    when(() => mockAdService.showInterstitialAd(any())).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0] as Function();
      callback();
      return Future.value();
    });
  });

  tearDown(() {
    workoutCubit.close();
  });

  group('WorkoutCubit Tests', () {
    test('initSession selects Workout A on Monday (not rest)', () async {
      // Monday is 2026-06-08
      final monday = DateTime(2026, 6, 8);
      await workoutCubit.initSession(mockDate: monday);

      expect(workoutCubit.state.isRestDay, isFalse);
      expect(workoutCubit.state.activeWorkout!.title, WorkoutRoutines.workoutA.title);
      expect(workoutCubit.state.completedSets['floor_press'], [false, false, false]);
    });

    test('initSession selects Rest Day on Tuesday', () async {
      // Tuesday is 2026-06-09
      final tuesday = DateTime(2026, 6, 9);
      await workoutCubit.initSession(mockDate: tuesday);

      expect(workoutCubit.state.isRestDay, isTrue);
      expect(workoutCubit.state.nextRoutineDay, 'Wednesday');
    });

    test('initSession alternates to Workout B if last session was Workout A', () async {
      final lastLog = WorkoutLog(
        id: '1',
        date: DateTime(2026, 6, 5),
        workoutType: WorkoutRoutines.workoutA.title,
        exercises: [],
        durationMinutes: 30,
        caloriesBurned: 100,
      );
      when(() => mockWorkoutRepository.loadWorkoutLogs()).thenAnswer((_) async => [lastLog]);

      final monday = DateTime(2026, 6, 8);
      await workoutCubit.initSession(mockDate: monday);

      expect(workoutCubit.state.activeWorkout!.title, WorkoutRoutines.workoutB.title);
    });

    test('bypassRestDay clears rest state', () async {
      final tuesday = DateTime(2026, 6, 9);
      await workoutCubit.initSession(mockDate: tuesday);
      expect(workoutCubit.state.isRestDay, isTrue);

      workoutCubit.bypassRestDay();
      expect(workoutCubit.state.isRestDay, isFalse);
    });

    test('startWorkout triggers ad fetch', () {
      workoutCubit.startWorkout();
      verify(() => mockAdService.loadInterstitialAd()).called(1);
    });

    test('toggleSet updates completion state', () async {
      final monday = DateTime(2026, 6, 8);
      await workoutCubit.initSession(mockDate: monday);

      workoutCubit.toggleSet('floor_press', 0);
      expect(workoutCubit.state.completedSets['floor_press'], [true, false, false]);

      workoutCubit.toggleSet('floor_press', 0);
      expect(workoutCubit.state.completedSets['floor_press'], [false, false, false]);
    });

    test('checking final exercise set 3 saves log and triggers interstitial', () async {
      final monday = DateTime(2026, 6, 8);
      await workoutCubit.initSession(mockDate: monday);
      workoutCubit.startWorkout();

      // Complete all exercises up to the final set of the final exercise
      final exercises = WorkoutRoutines.workoutA.exercises;
      for (int i = 0; i < exercises.length - 1; i++) {
        workoutCubit.toggleSet(exercises[i].id, 0);
        workoutCubit.toggleSet(exercises[i].id, 1);
        workoutCubit.toggleSet(exercises[i].id, 2);
      }

      // Check first two sets of final exercise
      final finalId = exercises.last.id;
      workoutCubit.toggleSet(finalId, 0);
      workoutCubit.toggleSet(finalId, 1);

      // Now toggle final set (index 2) -> triggers finish and shows ad
      workoutCubit.toggleSet(finalId, 2);

      await Future.delayed(Duration.zero);

      expect(workoutCubit.state.isWorkoutFinished, isTrue);
      verify(() => mockWorkoutRepository.addWorkoutLog(any())).called(1);
      verify(() => mockAdService.showInterstitialAd(any())).called(1);
    });
  });
}
