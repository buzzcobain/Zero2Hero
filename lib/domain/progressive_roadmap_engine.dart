import '../data/models/workout_log.dart';

enum RoadmapStage {
  stage1, // Weeks 1-2: Initial Conditioning (3x10 at Initial Weight)
  stage2, // Weeks 3-4: Rep Expansion (10 -> 12 -> 15 reps, weight static)
  stage3, // Weeks 5-8: Micro-Loading (+1.0kg, reset to 3x10, scale to 12)
  stage4, // Weeks 9+: Peak Capacity (+1.0kg again once 3x12 is cleared, reset to 10)
}

class SessionTarget {
  final RoadmapStage stage;
  final double weightKg;
  final int targetReps;

  const SessionTarget({
    required this.stage,
    required this.weightKg,
    required this.targetReps,
  });
}

class ProgressiveRoadmapEngine {
  static SessionTarget calculateTarget({
    required String exerciseId,
    required double initialWeight,
    required List<WorkoutLog> history,
    required DateTime currentDate,
  }) {
    // Sort history chronologically
    final sortedHistory = List<WorkoutLog>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Determine current week
    int weeksElapsed = 1;
    if (sortedHistory.isNotEmpty) {
      final firstWorkoutDate = sortedHistory.first.date;
      final diffDays = currentDate.difference(firstWorkoutDate).inDays;
      weeksElapsed = (diffDays / 7).floor() + 1;
      if (weeksElapsed < 1) weeksElapsed = 1;
    }

    RoadmapStage currentStage;
    if (weeksElapsed <= 2) {
      currentStage = RoadmapStage.stage1;
    } else if (weeksElapsed <= 4) {
      currentStage = RoadmapStage.stage2;
    } else if (weeksElapsed <= 8) {
      currentStage = RoadmapStage.stage3;
    } else {
      currentStage = RoadmapStage.stage4;
    }

    // Simulate chronological progression to find weight and target reps
    double weight = initialWeight;
    int targetReps = 10;
    bool achieved3x15AtInitial = false;
    bool achieved3x12AtStage3 = false;

    // Filter logs that actually contain this exercise and are before currentDate
    final exerciseLogs = <Map<String, dynamic>>[];
    for (var log in sortedHistory) {
      if (log.date.isAfter(currentDate) || log.date.isAtSameMomentAs(currentDate)) {
        continue;
      }
      final exerciseLog = log.exercises.firstWhere(
        (e) => e.exerciseId == exerciseId,
        orElse: () => ExerciseLog(exerciseId: '', weightKg: 0, reps: []),
      );
      if (exerciseLog.exerciseId.isNotEmpty) {
        // Determine week elapsed at log date
        final diffDays = log.date.difference(sortedHistory.first.date).inDays;
        int logWeek = (diffDays / 7).floor() + 1;
        if (logWeek < 1) logWeek = 1;

        exerciseLogs.add({
          'log': exerciseLog,
          'week': logWeek,
        });
      }
    }

    // Step through past sessions chronologically to update simulator state
    for (var item in exerciseLogs) {
      final log = item['log'] as ExerciseLog;
      final logWeek = item['week'] as int;

      RoadmapStage logStage;
      if (logWeek <= 2) {
        logStage = RoadmapStage.stage1;
      } else if (logWeek <= 4) {
        logStage = RoadmapStage.stage2;
      } else if (logWeek <= 8) {
        logStage = RoadmapStage.stage3;
      } else {
        logStage = RoadmapStage.stage4;
      }

      // Check if user completed all 3 sets at or above current targetReps
      bool completedTarget = log.reps.length >= 3 && log.reps.every((r) => r >= targetReps);

      if (logStage == RoadmapStage.stage1) {
        weight = initialWeight;
        targetReps = 10;
      } else if (logStage == RoadmapStage.stage2) {
        weight = initialWeight;
        if (completedTarget) {
          if (targetReps == 10) {
            targetReps = 12;
          } else if (targetReps == 12) {
            targetReps = 15;
            achieved3x15AtInitial = true;
          } else if (targetReps == 15) {
            achieved3x15AtInitial = true;
          }
        }
      } else if (logStage == RoadmapStage.stage3) {
        if (achieved3x15AtInitial) {
          weight = initialWeight + 1.0;
          if (targetReps == 15) {
            targetReps = 10;
          }
          if (completedTarget) {
            if (targetReps == 10) {
              targetReps = 12;
            } else if (targetReps == 12) {
              achieved3x12AtStage3 = true;
            }
          }
        } else {
          weight = initialWeight;
          if (completedTarget) {
            if (targetReps == 10) {
              targetReps = 12;
            } else if (targetReps == 12) {
              targetReps = 15;
              achieved3x15AtInitial = true;
            }
          }
        }
      } else {
        // Stage 4 (Weeks 9+)
        if (achieved3x12AtStage3) {
          weight = initialWeight + 2.0;
          if (targetReps == 12) {
            targetReps = 10;
          }
          if (completedTarget) {
            if (targetReps == 10) {
              targetReps = 12;
            }
          }
        } else if (achieved3x15AtInitial) {
          weight = initialWeight + 1.0;
          if (targetReps == 15) {
            targetReps = 10;
          }
          if (completedTarget) {
            if (targetReps == 10) {
              targetReps = 12;
            } else if (targetReps == 12) {
              achieved3x12AtStage3 = true;
            }
          }
        } else {
          weight = initialWeight;
          if (completedTarget) {
            if (targetReps == 10) {
              targetReps = 12;
            } else if (targetReps == 12) {
              targetReps = 15;
              achieved3x15AtInitial = true;
            }
          }
        }
      }
    }

    // Now calculate next session's configuration (currentDate)
    double nextWeight = weight;
    int nextTargetReps = targetReps;

    if (currentStage == RoadmapStage.stage1) {
      nextWeight = initialWeight;
      nextTargetReps = 10;
    } else if (currentStage == RoadmapStage.stage2) {
      nextWeight = initialWeight;
      if (exerciseLogs.isNotEmpty) {
        final lastItem = exerciseLogs.last;
        final lastLog = lastItem['log'] as ExerciseLog;
        bool lastCompleted = lastLog.reps.length >= 3 && lastLog.reps.every((r) => r >= targetReps);
        if (lastCompleted) {
          if (targetReps == 10) {
            nextTargetReps = 12;
          } else if (targetReps == 12) {
            nextTargetReps = 15;
          } else {
            nextTargetReps = 15;
          }
        }
      }
    } else if (currentStage == RoadmapStage.stage3) {
      if (exerciseLogs.isNotEmpty) {
        final lastItem = exerciseLogs.last;
        final lastLog = lastItem['log'] as ExerciseLog;
        bool lastCompleted = lastLog.reps.length >= 3 && lastLog.reps.every((r) => r >= targetReps);
        if (lastCompleted) {
          if (targetReps == 10) {
            nextTargetReps = 12;
          } else if (targetReps == 12) {
            achieved3x12AtStage3 = true;
          } else if (targetReps == 15) {
            achieved3x15AtInitial = true;
            nextTargetReps = 10;
          }
        }
      }
      
      if (achieved3x15AtInitial || targetReps == 15) {
        nextWeight = initialWeight + 1.0;
        if (nextTargetReps == 15) {
          nextTargetReps = 10;
        }
      } else {
        nextWeight = initialWeight;
      }
    } else {
      // Stage 4
      if (exerciseLogs.isNotEmpty) {
        final lastItem = exerciseLogs.last;
        final lastLog = lastItem['log'] as ExerciseLog;
        bool lastCompleted = lastLog.reps.length >= 3 && lastLog.reps.every((r) => r >= targetReps);
        if (lastCompleted) {
          if (targetReps == 10) {
            nextTargetReps = 12;
          } else if (targetReps == 12) {
            achieved3x12AtStage3 = true;
            nextTargetReps = 10;
          } else if (targetReps == 15) {
            achieved3x15AtInitial = true;
            nextTargetReps = 10;
          }
        }
      }

      if (achieved3x12AtStage3 || (targetReps == 12 && nextTargetReps == 10 && nextWeight == initialWeight + 1.0)) {
        nextWeight = initialWeight + 2.0;
        nextTargetReps = 10;
      } else if (achieved3x15AtInitial || targetReps == 15) {
        nextWeight = initialWeight + 1.0;
        if (nextTargetReps == 15) {
          nextTargetReps = 10;
        }
      } else {
        nextWeight = initialWeight;
      }
    }

    return SessionTarget(
      stage: currentStage,
      weightKg: nextWeight,
      targetReps: nextTargetReps,
    );
  }
}
