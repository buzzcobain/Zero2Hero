import '../data/models/workout_log.dart';

class WeeklyStats {
  final int repsThisWeek;
  final int repsThisMonth;
  final int repsTotal;
  final double weightTotalKg;
  final String animalEquivalent;
  final String animalEmoji;

  WeeklyStats({
    required this.repsThisWeek,
    required this.repsThisMonth,
    required this.repsTotal,
    required this.weightTotalKg,
    required this.animalEquivalent,
    required this.animalEmoji,
  });
}

class StatsEngine {
  static final List<Map<String, dynamic>> _animals = [
    {'name': 'Mouse', 'emoji': '🐁', 'weight': 0.0},
    {'name': 'Cat', 'emoji': '🐈', 'weight': 5.0},
    {'name': 'Dog', 'emoji': '🐕', 'weight': 20.0},
    {'name': 'Panda', 'emoji': '🐼', 'weight': 100.0},
    {'name': 'Gorilla', 'emoji': '🦍', 'weight': 200.0},
    {'name': 'Horse', 'emoji': '🐎', 'weight': 500.0},
    {'name': 'Great White Shark', 'emoji': '🦈', 'weight': 1000.0},
    {'name': 'Rhinoceros', 'emoji': '🦏', 'weight': 2000.0},
    {'name': 'Elephant', 'emoji': '🐘', 'weight': 5000.0},
    {'name': 'T-Rex', 'emoji': '🦖', 'weight': 8000.0},
    {'name': 'Blue Whale', 'emoji': '🐋', 'weight': 100000.0},
  ];

  static WeeklyStats computeStats(List<WorkoutLog> logs, DateTime currentDate) {
    int repsThisWeek = 0;
    int repsThisMonth = 0;
    int repsTotal = 0;
    double weightTotalKg = 0.0;

    // A week here is considered Monday to Sunday.
    // Calculate the start of the current week (Monday)
    final int currentWeekday = currentDate.weekday; // 1 = Monday, 7 = Sunday
    final DateTime startOfWeek = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - (currentWeekday - 1),
    );
    // End of week is the end of Sunday
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (var log in logs) {
      final logDate = log.date;
      int logReps = 0;
      double logWeightVolume = 0.0;

      for (var exercise in log.exercises) {
        for (var repCount in exercise.reps) {
          logReps += repCount;
          logWeightVolume += repCount * exercise.weightKg;
        }
      }

      repsTotal += logReps;
      weightTotalKg += logWeightVolume;

      // Check if in current week
      if (logDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          logDate.isBefore(endOfWeek)) {
        repsThisWeek += logReps;
      }

      // Check if in current month
      if (logDate.year == currentDate.year && logDate.month == currentDate.month) {
        repsThisMonth += logReps;
      }
    }

    // Find animal equivalent
    String animalName = 'Mouse';
    String animalEmoji = '🐁';
    
    for (var animal in _animals) {
      if (weightTotalKg >= animal['weight']) {
        animalName = animal['name'];
        animalEmoji = animal['emoji'];
      } else {
        break; // since list is sorted by weight
      }
    }

    return WeeklyStats(
      repsThisWeek: repsThisWeek,
      repsThisMonth: repsThisMonth,
      repsTotal: repsTotal,
      weightTotalKg: weightTotalKg,
      animalEquivalent: animalName,
      animalEmoji: animalEmoji,
    );
  }
}
