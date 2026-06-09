import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

class OnboardingState {
  final bool isCheckingProfile;
  final bool profileExists;
  final bool isLoading;
  final String? heightError;
  final String? weightError;
  final String? vestWeightError;
  final Map<String, String?> exerciseErrors;
  final bool isSuccess;

  const OnboardingState({
    this.isCheckingProfile = true,
    this.profileExists = false,
    this.isLoading = false,
    this.heightError,
    this.weightError,
    this.vestWeightError,
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
    required String heightStr,
    required String weightStr,
    required bool useWeightVest,
    required String vestWeightStr,
    required Map<String, String> exerciseStartingWeights,
  }) async {
    emit(state.copyWith(isLoading: true, heightError: null, weightError: null, vestWeightError: null, exerciseErrors: {}));

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

    if (heightErr != null || weightErr != null || vestWeightErr != null || exerciseErrors.values.any((e) => e != null)) {
      emit(state.copyWith(
        isLoading: false,
        heightError: heightErr,
        weightError: weightErr,
        vestWeightError: vestWeightErr,
        exerciseErrors: exerciseErrors,
      ));
      return;
    }

    final profile = UserProfile(
      heightCm: int.parse(heightStr),
      currentWeightKg: double.parse(weightStr),
      useWeightVest: useWeightVest,
      weightVestKg: useWeightVest ? double.parse(vestWeightStr) : 0.0,
    );

    final weights = ExerciseWeights(
      floorPress: double.parse(exerciseStartingWeights['floor_press']!),
      militaryPress: double.parse(exerciseStartingWeights['military_press']!),
      supinatingCurl: double.parse(exerciseStartingWeights['supinating_curl']!),
      crossHammer: double.parse(exerciseStartingWeights['cross_hammer']!),
      chairKickback: double.parse(exerciseStartingWeights['chair_kickback']!),
      uprightRow: double.parse(exerciseStartingWeights['upright_row']!),
      shrug: double.parse(exerciseStartingWeights['shrug']!),
      rearFlye: double.parse(exerciseStartingWeights['rear_flye']!),
    );

    final userData = UserData(profile: profile, weights: weights);
    await _profileRepository.saveProfile(userData);

    emit(state.copyWith(isLoading: false, isSuccess: true, profileExists: true));
  }
}
