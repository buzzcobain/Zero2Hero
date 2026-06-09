import 'package:flutter_test/flutter_test.dart';
import 'package:zero2hero/domain/met_energy_engine.dart';

void main() {
  group('MetEnergyEngine Tests', () {
    test('calculateCalories weight training', () {
      final calories = MetEnergyEngine.calculateCalories(
        userWeightKg: 80.0,
        useWeightVest: false,
        durationMinutes: 60.0,
      );
      // Expected = ((3.5 * 3.5 * 80) / 200) * 60 = 294.0
      expect(calories, closeTo(294.0, 0.001));
    });

    test('calculateCalories weight vest walking', () {
      final calories = MetEnergyEngine.calculateCalories(
        userWeightKg: 80.0,
        useWeightVest: true,
        durationMinutes: 60.0,
      );
      // Expected = ((5.5 * 3.5 * 80) / 200) * 60 = 462.0
      expect(calories, closeTo(462.0, 0.001));
    });
  });
}
