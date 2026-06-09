class MetEnergyEngine {
  static const double weightTrainingMet = 3.5;
  static const double weightedVestMet = 5.5;

  static double calculateCalories({
    required double userWeightKg,
    required bool useWeightVest,
    required double durationMinutes,
  }) {
    final met = useWeightVest ? weightedVestMet : weightTrainingMet;
    // Formula: Calories Burned = ((MET * 3.5 * User Weight in kg) / 200) * Duration in Minutes
    final calories = ((met * 3.5 * userWeightKg) / 200.0) * durationMinutes;
    return calories;
  }
}
