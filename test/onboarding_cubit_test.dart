import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zero2hero/data/models/user_profile.dart';
import 'package:zero2hero/data/repositories/profile_repository.dart';
import 'package:zero2hero/presentation/blocs/onboarding/onboarding_cubit.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late OnboardingCubit onboardingCubit;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    onboardingCubit = OnboardingCubit(mockProfileRepository);
    registerFallbackValue(
      UserData(
        profile: UserProfile(heightCm: 180, currentWeightKg: 75.0, useWeightVest: false, weightVestKg: 0),
        weights: ExerciseWeights(
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
        ),
      ),
    );
  });

  tearDown(() {
    onboardingCubit.close();
  });

  group('OnboardingCubit Tests', () {
    test('checkProfile sets exists flag', () async {
      when(() => mockProfileRepository.profileExists()).thenAnswer((_) async => true);
      
      await onboardingCubit.checkProfile();

      expect(onboardingCubit.state.profileExists, isTrue);
      expect(onboardingCubit.state.isCheckingProfile, isFalse);
    });

    test('saveProfile validates invalid inputs and sets errors', () async {
      await onboardingCubit.saveProfile(
        nameStr: 'Test',
        heightStr: '',
        heightFtStr: '',
        heightInStr: '',
        weightStr: 'abc',
        weightStStr: '',
        weightLbsStr: '',
        useWeightVest: true,
        vestWeightStr: '-5.0',
        vestWeightStStr: '',
        vestWeightLbsStr: '',
        useMetricSystem: true,
        selectedRoutines: ['chest_arms'],
        workoutSchedule: {},
        enableNotifications: false,
        notificationOffsetMinutes: 10,
        exerciseStartingWeights: {
          'floor_press': '',
          'military_press': 'invalid',
          'supinating_curl': '8.0',
          'cross_hammer': '8.0',
          'chair_kickback': '8.0',
          'upright_row': '8.0',
          'shrug': '8.0',
          'rear_flye': '8.0',
          'goblet_squat': '8.0',
          'romanian_deadlift': '8.0',
          'split_squat': '8.0',
          'calf_raise': '8.0',
        },
      );

      final state = onboardingCubit.state;
      expect(state.heightError, isNotNull);
      expect(state.weightError, isNotNull);
      expect(state.vestWeightError, isNotNull);
      expect(state.exerciseErrors['floor_press'], isNotNull);
      expect(state.exerciseErrors['military_press'], isNotNull);
      expect(state.exerciseErrors['supinating_curl'], isNull);
      expect(state.isSuccess, isFalse);
    });

    test('saveProfile saves valid inputs and triggers success', () async {
      when(() => mockProfileRepository.saveProfile(any())).thenAnswer((_) async => {});

      await onboardingCubit.saveProfile(
        nameStr: 'Test',
        heightStr: '180',
        heightFtStr: '',
        heightInStr: '',
        weightStr: '82.5',
        weightStStr: '',
        weightLbsStr: '',
        useWeightVest: true,
        vestWeightStr: '10.0',
        vestWeightStStr: '',
        vestWeightLbsStr: '',
        useMetricSystem: true,
        selectedRoutines: ['chest_arms'],
        workoutSchedule: {},
        enableNotifications: false,
        notificationOffsetMinutes: 10,
        exerciseStartingWeights: {
          'floor_press': '12.0',
          'military_press': '8.0',
          'supinating_curl': '8.0',
          'cross_hammer': '8.0',
          'chair_kickback': '8.0',
          'upright_row': '8.0',
          'shrug': '8.0',
          'rear_flye': '8.0',
          'goblet_squat': '8.0',
          'romanian_deadlift': '8.0',
          'split_squat': '8.0',
          'calf_raise': '8.0',
        },
      );

      final state = onboardingCubit.state;
      expect(state.heightError, isNull);
      expect(state.weightError, isNull);
      expect(state.vestWeightError, isNull);
      expect(state.isSuccess, isTrue);
      expect(state.profileExists, isTrue);

      verify(() => mockProfileRepository.saveProfile(any())).called(1);
    });
  });
}
