import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/workout_definitions.dart';
import '../../../data/models/workout_log.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../domain/met_energy_engine.dart';
import '../../../domain/progressive_roadmap_engine.dart';
import '../../../infrastructure/ad_service.dart';

class WorkoutState {
  final bool isLoading;
  final bool isRestDay;
  final String nextRoutineDay;
  final WorkoutDefinition? activeWorkout;
  final Map<String, List<bool>> completedSets;
  final Map<String, SessionTarget> targets;
  final bool isTimerActive;
  final int timerRemaining;
  final int timerTotal;
  final bool timerFlashSignal;
  final double caloriesBurned;
  final bool isWorkoutFinished;
  final bool triggerCameraVault;
  final UserData? userData;

  const WorkoutState({
    this.isLoading = false,
    this.isRestDay = false,
    this.nextRoutineDay = '',
    this.activeWorkout,
    this.completedSets = const {},
    this.targets = const {},
    this.isTimerActive = false,
    this.timerRemaining = 0,
    this.timerTotal = 0,
    this.timerFlashSignal = false,
    this.caloriesBurned = 0.0,
    this.isWorkoutFinished = false,
    this.triggerCameraVault = false,
    this.userData,
  });

  WorkoutState copyWith({
    bool? isLoading,
    bool? isRestDay,
    String? nextRoutineDay,
    WorkoutDefinition? activeWorkout,
    Map<String, List<bool>>? completedSets,
    Map<String, SessionTarget>? targets,
    bool? isTimerActive,
    int? timerRemaining,
    int? timerTotal,
    bool? timerFlashSignal,
    double? caloriesBurned,
    bool? isWorkoutFinished,
    bool? triggerCameraVault,
    UserData? userData,
  }) {
    return WorkoutState(
      isLoading: isLoading ?? this.isLoading,
      isRestDay: isRestDay ?? this.isRestDay,
      nextRoutineDay: nextRoutineDay ?? this.nextRoutineDay,
      activeWorkout: activeWorkout ?? this.activeWorkout,
      completedSets: completedSets ?? this.completedSets,
      targets: targets ?? this.targets,
      isTimerActive: isTimerActive ?? this.isTimerActive,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      timerTotal: timerTotal ?? this.timerTotal,
      timerFlashSignal: timerFlashSignal ?? this.timerFlashSignal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      isWorkoutFinished: isWorkoutFinished ?? this.isWorkoutFinished,
      triggerCameraVault: triggerCameraVault ?? this.triggerCameraVault,
      userData: userData ?? this.userData,
    );
  }
}

class WorkoutCubit extends Cubit<WorkoutState> {
  final ProfileRepository _profileRepository;
  final WorkoutRepository _workoutRepository;
  final AdServiceInterface _adService;

  AdServiceInterface get adService => _adService;
  
  Timer? _timer;
  DateTime? _workoutStartTime;

  WorkoutCubit({
    required ProfileRepository profileRepository,
    required WorkoutRepository workoutRepository,
    required AdServiceInterface adService,
  })  : _profileRepository = profileRepository,
        _workoutRepository = workoutRepository,
        _adService = adService,
        super(const WorkoutState());

  Future<void> initSession({DateTime? mockDate}) async {
    emit(state.copyWith(isLoading: true));
    final currentDate = mockDate ?? DateTime.now();

    final profileData = await _profileRepository.loadProfile();
    final logs = await _workoutRepository.loadWorkoutLogs();

    // 1. Determine if Rest Day
    // Weekdays in Dart: Mon=1, Wed=3, Fri=5
    final weekday = currentDate.weekday;
    final isRest = weekday != 1 && weekday != 3 && weekday != 5;
    
    String nextDay = '';
    if (weekday == 2) nextDay = 'Wednesday';
    else if (weekday == 4) nextDay = 'Friday';
    else nextDay = 'Monday';

    // 2. Select Routine (alternating)
    WorkoutDefinition selectedRoutine = WorkoutRoutines.workoutA;
    if (logs.isNotEmpty) {
      final lastLog = logs.last;
      if (lastLog.workoutType == WorkoutRoutines.workoutA.title) {
        selectedRoutine = WorkoutRoutines.workoutB;
      } else {
        selectedRoutine = WorkoutRoutines.workoutA;
      }
    }

    // 3. Compute target weight and reps for each exercise using ProgressiveRoadmapEngine
    final targets = <String, SessionTarget>{};
    if (profileData != null) {
      for (var exercise in selectedRoutine.exercises) {
        final initialWeight = profileData.weights.getWeightForExercise(exercise.id);
        final target = ProgressiveRoadmapEngine.calculateTarget(
          exerciseId: exercise.id,
          initialWeight: initialWeight,
          history: logs,
          currentDate: currentDate,
        );
        targets[exercise.id] = target;
      }
    }

    // Initialize set tracking
    final completedSets = <String, List<bool>>{};
    for (var exercise in selectedRoutine.exercises) {
      completedSets[exercise.id] = [false, false, false];
    }

    emit(state.copyWith(
      isLoading: false,
      isRestDay: isRest,
      nextRoutineDay: nextDay,
      activeWorkout: selectedRoutine,
      completedSets: completedSets,
      targets: targets,
      userData: profileData,
    ));
  }

  void startWorkout() {
    _workoutStartTime = DateTime.now();
    // Load interstitial ad in background
    _adService.loadInterstitialAd();
  }

  void toggleSet(String exerciseId, int setIndex) {
    if (state.activeWorkout == null) return;
    
    final currentSets = List<bool>.from(state.completedSets[exerciseId] ?? [false, false, false]);
    final wasChecked = currentSets[setIndex];
    currentSets[setIndex] = !wasChecked;

    final newCompletedSets = Map<String, List<bool>>.from(state.completedSets);
    newCompletedSets[exerciseId] = currentSets;

    emit(state.copyWith(completedSets: newCompletedSets));

    // If we ticked the set to complete, start the rest timer
    if (!wasChecked) {
      final exercise = state.activeWorkout!.exercises.firstWhere((e) => e.id == exerciseId);
      _startTimer(exercise.restSeconds);

      // Check if this is the 3rd set of the 4th (final) exercise of the routine
      final finalExercise = state.activeWorkout!.exercises.last;
      final isFinalExercise = exerciseId == finalExercise.id;
      final isSet3 = setIndex == 2;

      if (isFinalExercise && isSet3) {
        // Workout finished trigger!
        _finishWorkout(mockDate: _workoutStartTime);
      }
    }
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    emit(state.copyWith(
      isTimerActive: true,
      timerRemaining: seconds,
      timerTotal: seconds,
      timerFlashSignal: false,
    ));

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.timerRemaining > 1) {
        emit(state.copyWith(timerRemaining: state.timerRemaining - 1));
      } else {
        _timer?.cancel();
        // Trigger haptic signal & screen flash
        emit(state.copyWith(
          timerRemaining: 0,
          timerFlashSignal: true,
        ));
        // Reset timer signal state after 1 second
        Future.delayed(const Duration(milliseconds: 800), () {
          emit(state.copyWith(isTimerActive: false, timerFlashSignal: false));
        });
      }
    });
  }

  void forceCloseTimer() {
    _timer?.cancel();
    emit(state.copyWith(isTimerActive: false, timerFlashSignal: false));
  }

  Future<void> _finishWorkout({DateTime? mockDate}) async {
    final startTime = _workoutStartTime ?? DateTime.now();
    final duration = DateTime.now().difference(startTime).inSeconds / 60.0;
    
    final userWeight = state.userData?.profile.currentWeightKg ?? 70.0;
    final useVest = state.userData?.profile.useWeightVest ?? false;
    
    // MET Energy Expenditure Engine calculation
    final calories = MetEnergyEngine.calculateCalories(
      userWeightKg: userWeight,
      useWeightVest: useVest,
      durationMinutes: duration,
    );

    // Build the workout logs for storage
    final exerciseLogs = <ExerciseLog>[];
    for (var exercise in state.activeWorkout!.exercises) {
      final target = state.targets[exercise.id];
      final sets = state.completedSets[exercise.id] ?? [false, false, false];
      
      final loggedReps = <int>[];
      for (int i = 0; i < sets.length; i++) {
        if (sets[i]) {
          loggedReps.add(target?.targetReps ?? 10);
        } else {
          loggedReps.add(0);
        }
      }

      exerciseLogs.add(ExerciseLog(
        exerciseId: exercise.id,
        weightKg: target?.weightKg ?? 8.0,
        reps: loggedReps,
      ));
    }

    final newLog = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: mockDate ?? DateTime.now(),
      workoutType: state.activeWorkout!.title,
      exercises: exerciseLogs,
      durationMinutes: duration,
      caloriesBurned: calories,
    );

    // Save logs offline
    await _workoutRepository.addWorkoutLog(newLog);

    // Update weights local file if there are micro-loading weight increments
    if (state.userData != null) {
      var updatedWeights = state.userData!.weights;
      bool weightsChanged = false;
      for (var exercise in state.activeWorkout!.exercises) {
        final currentTarget = state.targets[exercise.id];
        if (currentTarget != null) {
          final registeredWeight = state.userData!.weights.getWeightForExercise(exercise.id);
          if (currentTarget.weightKg != registeredWeight) {
            updatedWeights = updatedWeights.copyWithExercise(exercise.id, currentTarget.weightKg);
            weightsChanged = true;
          }
        }
      }
      if (weightsChanged) {
        final updatedData = UserData(profile: state.userData!.profile, weights: updatedWeights);
        await _profileRepository.saveProfile(updatedData);
      }
    }

    // Trigger Interstitial Ad
    await _adService.showInterstitialAd(() {
      // Once ad is dismissed: check if today is Friday (weekday == 5)
      final isFriday = DateTime.now().weekday == 5;
      emit(state.copyWith(
        caloriesBurned: calories,
        isWorkoutFinished: true,
        triggerCameraVault: isFriday,
      ));
    });
  }

  void bypassRestDay() {
    emit(state.copyWith(isRestDay: false));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
