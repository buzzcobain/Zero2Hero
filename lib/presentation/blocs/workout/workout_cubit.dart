import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/workout_definitions.dart';
import '../../../data/models/workout_log.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../domain/met_energy_engine.dart';
import '../../../domain/progressive_roadmap_engine.dart';
import '../../../domain/stats_engine.dart';
import '../../../infrastructure/ad_service.dart';
import '../../../infrastructure/notification_service.dart';

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
  final List<WorkoutDefinition> availableRoutines;
  final WeeklyStats? weeklyStats;

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
    this.availableRoutines = const [],
    this.weeklyStats,
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
    List<WorkoutDefinition>? availableRoutines,
    WeeklyStats? weeklyStats,
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
      availableRoutines: availableRoutines ?? this.availableRoutines,
      weeklyStats: weeklyStats ?? this.weeklyStats,
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
    final schedule = profileData?.profile.workoutSchedule ?? {'1': '07:00', '3': '07:00', '5': '07:00'};
    final workoutDays = schedule.keys.map((e) => int.tryParse(e) ?? 1).toList();
    workoutDays.sort();
    if (workoutDays.isEmpty) workoutDays.add(1); // fallback

    final weekday = currentDate.weekday;
    final isRest = !workoutDays.contains(weekday);
    
    String nextDay = '';
    int nextDayInt = workoutDays.firstWhere((day) => day > weekday, orElse: () => workoutDays.first);
    nextDay = _getWeekdayName(nextDayInt);

    // Ensure notifications are scheduled
    if (profileData != null) {
      NotificationService().scheduleWorkoutReminders(
        profileData.profile.workoutSchedule,
        profileData.profile.notificationOffsetMinutes,
        profileData.profile.enableNotifications,
      );
    }

    // 2. Select Routine (alternating based on user's selected routines)
    List<String> selectedRoutineIds = profileData?.profile.selectedRoutines ?? ['chest_arms', 'shoulders_back', 'legs'];
    if (selectedRoutineIds.isEmpty) {
      selectedRoutineIds = ['chest_arms']; // fallback
    }

    final availableRoutines = selectedRoutineIds.map((id) => WorkoutRoutines.getById(id)).toList();
    
    WorkoutDefinition selectedRoutine = availableRoutines.first;
    if (logs.isNotEmpty) {
      final lastLog = logs.last;
      final lastRoutineIndex = availableRoutines.indexWhere((r) => r.title == lastLog.workoutType);
      if (lastRoutineIndex != -1) {
        final nextIndex = (lastRoutineIndex + 1) % availableRoutines.length;
        selectedRoutine = availableRoutines[nextIndex];
      } else {
        selectedRoutine = availableRoutines.first;
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
      availableRoutines: availableRoutines,
    ));
  }

  void cycleRoutine() {
    if (state.availableRoutines.isEmpty || state.activeWorkout == null) return;
    final currentIndex = state.availableRoutines.indexWhere((r) => r.title == state.activeWorkout!.title);
    if (currentIndex == -1) return;
    
    final nextIndex = (currentIndex + 1) % state.availableRoutines.length;
    final selectedRoutine = state.availableRoutines[nextIndex];

    // Recompute targets and sets for the new routine
    final targets = <String, SessionTarget>{};
    if (state.userData != null) {
      for (var exercise in selectedRoutine.exercises) {
        final initialWeight = state.userData!.weights.getWeightForExercise(exercise.id);
        // Note: For simplicity we aren't reloading history here, but we can assume we just use the initial weight
        // or a simple target. Ideally we pass the history from initSession. We'll use the profile weight.
        targets[exercise.id] = SessionTarget(stage: RoadmapStage.stage1, weightKg: initialWeight, targetReps: 10);
      }
    }

    final completedSets = <String, List<bool>>{};
    for (var exercise in selectedRoutine.exercises) {
      completedSets[exercise.id] = [false, false, false];
    }

    emit(state.copyWith(
      activeWorkout: selectedRoutine,
      targets: targets,
      completedSets: completedSets,
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

    // Calculate weekly stats if it's the end of their workout week
    final schedule = state.userData?.profile.workoutSchedule ?? {'1': '07:00', '3': '07:00', '5': '07:00'};
    final workoutDays = schedule.keys.map((e) => int.tryParse(e) ?? 1).toList();
    workoutDays.sort();
    if (workoutDays.isEmpty) workoutDays.add(1);

    final todayWeekday = (mockDate ?? DateTime.now()).weekday;
    final isEndOfWeek = todayWeekday == workoutDays.last;

    WeeklyStats? computedStats;
    if (isEndOfWeek) {
      final allLogs = await _workoutRepository.loadWorkoutLogs();
      computedStats = StatsEngine.computeStats(allLogs, mockDate ?? DateTime.now());
    }

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
        weeklyStats: computedStats,
      ));
    });
  }

  Future<void> toggleMetricSystem(bool useMetric) async {
    if (state.userData != null) {
      final updatedProfile = state.userData!.profile.copyWith(useMetricSystem: useMetric);
      final updatedData = UserData(profile: updatedProfile, weights: state.userData!.weights);
      await _profileRepository.saveProfile(updatedData);
      emit(state.copyWith(userData: updatedData));
    }
  }

  Future<void> updateBodyProfile(double newWeightKg, bool useVest, double vestWeightKg) async {
    if (state.userData != null) {
      final updatedProfile = state.userData!.profile.copyWith(
        currentWeightKg: newWeightKg,
        useWeightVest: useVest,
        weightVestKg: vestWeightKg,
      );
      final updatedData = UserData(profile: updatedProfile, weights: state.userData!.weights);
      await _profileRepository.saveProfile(updatedData);
      emit(state.copyWith(userData: updatedData));
    }
  }

  Future<void> updateExerciseWeights(Map<String, double> newWeightsKg) async {
    if (state.userData != null) {
      var updatedWeights = state.userData!.weights;
      newWeightsKg.forEach((key, value) {
        updatedWeights = updatedWeights.copyWithExercise(key, value);
      });
      final updatedData = UserData(profile: state.userData!.profile, weights: updatedWeights);
      await _profileRepository.saveProfile(updatedData);
      
      final newTargets = Map<String, SessionTarget>.from(state.targets);
      for (var exerciseId in newWeightsKg.keys) {
        if (newTargets.containsKey(exerciseId)) {
          final oldTarget = newTargets[exerciseId]!;
          newTargets[exerciseId] = SessionTarget(
            stage: oldTarget.stage,
            weightKg: newWeightsKg[exerciseId]!,
            targetReps: oldTarget.targetReps,
          );
        }
      }

      emit(state.copyWith(userData: updatedData, targets: newTargets));
    }
  }

  Future<void> updateSelectedRoutines(List<String> routines) async {
    if (state.userData != null) {
      final updatedProfile = state.userData!.profile.copyWith(selectedRoutines: routines);
      final updatedData = UserData(profile: updatedProfile, weights: state.userData!.weights);
      await _profileRepository.saveProfile(updatedData);
      emit(state.copyWith(userData: updatedData));
    }
  }

  Future<void> updateWorkoutSchedule(Map<String, String> schedule, bool enabled, int offset) async {
    if (state.userData != null) {
      final updatedProfile = state.userData!.profile.copyWith(
        workoutSchedule: schedule,
        enableNotifications: enabled,
        notificationOffsetMinutes: offset,
      );
      final updatedData = UserData(profile: updatedProfile, weights: state.userData!.weights);
      await _profileRepository.saveProfile(updatedData);
      
      await NotificationService().scheduleWorkoutReminders(schedule, offset, enabled);

      emit(state.copyWith(userData: updatedData));
    }
  }

  void bypassRestDay() {
    emit(state.copyWith(isRestDay: false));
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return 'Monday';
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
