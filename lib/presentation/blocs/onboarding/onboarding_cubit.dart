import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../utils/weight_converter.dart';

class OnboardingState {
  final bool isCheckingProfile;
  final bool profileExists;
  final bool isLoading;
  final String? heightError;
  final String? weightError;
  final String? vestWeightError;
  final String? routineError;
  final Map<String, String?> exerciseErrors;
  final bool isSuccess;

  const OnboardingState({
    this.isCheckingProfile = true,
    this.profileExists = false,
    this.isLoading = false,
    this.heightError,
    this.weightError,
    this.vestWeightError,
    this.routineError,
    this.exerciseErrors = const {},
    this.isSuccess = false,
  });

  OnboardingState copyWith({
    bool? isCheckingProfile,
    bool? profileExists,
    bool? isLoading,
    String? heightError,
    String? weightError,
    String? vestWeightError,
    String? routineError,
    Map<String, String?>? exerciseErrors,
    bool? isSuccess,
  }) {
    return OnboardingState(
      isCheckingProfile: isCheckingProfile ?? this.isCheckingProfile,
      profileExists: profileExists ?? this.profileExists,
      isLoading: isLoading ?? this.isLoading,
      heightError: heightError ?? this.heightError,
      weightError: weightError ?? this.weightError,
      vestWeightError: vestWeightError ?? this.vestWeightError,
      routineError: routineError ?? this.routineError,
      exerciseErrors: exerciseErrors ?? this.exerciseErrors,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final ProfileRepository _profileRepository;

  OnboardingCubit(this._profileRepository) : super(const OnboardingState());

  Future<void> checkProfile() async {
    emit(state.copyWith(isCheckingProfile: true));
    final exists = await _profileRepository.profileExists();
    emit(state.copyWith(isCheckingProfile: false, profileExists: exists));
  }

  Future<void> saveProfile({
    required String nameStr,
    required String heightStr,
    required String weightStr,
    required bool useWeightVest,
    required String vestWeightStr,
    required Map<String, String> exerciseStartingWeights,
    required bool useMetricSystem,
    required List<String> selectedRoutines,
  }) async {
    emit(state.copyWith(isLoading: true, heightError: null, weightError: null, vestWeightError: null, routineError: null, exerciseErrors: {}));

    final numRegex = RegExp(r'^\d+(\.\d+)?$');
    final intRegex = RegExp(r'^\d+$');

    String? heightErr;
    if (heightStr.trim().isEmpty) {
      heightErr = 'Height is required';
    } else if (!intRegex.hasMatch(heightStr)) {
      heightErr = 'Must be a whole number';
    } else if (int.parse(heightStr) <= 0) {
      heightErr = 'Must be greater than 0';
    }

    String? weightErr;
    if (weightStr.trim().isEmpty) {
      weightErr = 'Weight is required';
    } else if (!numRegex.hasMatch(weightStr)) {
      weightErr = 'Must be a valid number';
    } else if (double.parse(weightStr) <= 0) {
      weightErr = 'Must be greater than 0';
    }

    String? vestWeightErr;
    if (useWeightVest) {
      if (vestWeightStr.trim().isEmpty) {
        vestWeightErr = 'Vest weight is required';
      } else if (!numRegex.hasMatch(vestWeightStr)) {
        vestWeightErr = 'Must be a valid number';
      } else if (double.parse(vestWeightStr) < 0) {
        vestWeightErr = 'Must be 0 or positive';
      }
    }

    String? routineErr;
    if (selectedRoutines.isEmpty) {
      routineErr = 'Please select at least one routine.';
    }

    final exerciseErrors = <String, String?>{};
    for (var entry in exerciseStartingWeights.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val.trim().isEmpty) {
        exerciseErrors[key] = 'Required';
      } else if (!numRegex.hasMatch(val)) {
        exerciseErrors[key] = 'Invalid';
      } else if (double.parse(val) < 0) {
        exerciseErrors[key] = 'Negative';
      }
    }

    if (heightErr != null || weightErr != null || vestWeightErr != null || routineErr != null || exerciseErrors.values.any((e) => e != null)) {
      emit(state.copyWith(
        isLoading: false,
        heightError: heightErr,
        weightError: weightErr,
        vestWeightError: vestWeightErr,
        routineError: routineErr,
        exerciseErrors: exerciseErrors,
      ));
      return;
    }

    final profile = UserProfile(
      name: nameStr.trim().isNotEmpty ? nameStr.trim() : 'User',
      heightCm: int.parse(heightStr),
      currentWeightKg: WeightConverter.displayToKg(double.parse(weightStr), useMetricSystem),
      useWeightVest: useWeightVest,
      weightVestKg: useWeightVest ? WeightConverter.displayToKg(double.parse(vestWeightStr), useMetricSystem) : 0.0,
      useMetricSystem: useMetricSystem,
      selectedRoutines: selectedRoutines,
    );

    final weights = ExerciseWeights(
      floorPress: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['floor_press'] ?? '8.0'), useMetricSystem),
      militaryPress: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['military_press'] ?? '8.0'), useMetricSystem),
      supinatingCurl: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['supinating_curl'] ?? '8.0'), useMetricSystem),
      crossHammer: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['cross_hammer'] ?? '8.0'), useMetricSystem),
      chairKickback: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['chair_kickback'] ?? '8.0'), useMetricSystem),
      uprightRow: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['upright_row'] ?? '8.0'), useMetricSystem),
      shrug: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['shrug'] ?? '8.0'), useMetricSystem),
      rearFlye: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['rear_flye'] ?? '8.0'), useMetricSystem),
      gobletSquat: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['goblet_squat'] ?? '8.0'), useMetricSystem),
      romanianDeadlift: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['romanian_deadlift'] ?? '8.0'), useMetricSystem),
      splitSquat: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['split_squat'] ?? '8.0'), useMetricSystem),
      calfRaise: WeightConverter.displayToKg(double.parse(exerciseStartingWeights['calf_raise'] ?? '8.0'), useMetricSystem),
    );

    final userData = UserData(profile: profile, weights: weights);
    await _profileRepository.saveProfile(userData);

    emit(state.copyWith(isLoading: false, isSuccess: true, profileExists: true));
  }
}
