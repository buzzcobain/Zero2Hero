import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../../utils/weight_converter.dart';

class UpdateWeightsView extends StatefulWidget {
  const UpdateWeightsView({super.key});

  @override
  State<UpdateWeightsView> createState() => _UpdateWeightsViewState();
}

class _UpdateWeightsViewState extends State<UpdateWeightsView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isMetric = true;

  final Map<String, String> _exerciseNames = {};
  List<String> _selectedRoutines = [];

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkoutCubit>().state;
    if (state.userData != null) {
      _isMetric = state.userData!.profile.useMetricSystem;
      _selectedRoutines = state.userData!.profile.selectedRoutines;
      final weights = state.userData!.weights;

      if (_selectedRoutines.contains('chest_arms')) {
        _exerciseNames['floor_press'] = 'Dumbbell Floor Press';
        _exerciseNames['supinating_curl'] = 'Supinating Bicep Curl';
        _exerciseNames['cross_hammer'] = 'Cross-Body Hammer Curl';
        _exerciseNames['chair_kickback'] = 'Dining Chair Kickback';
      }
      if (_selectedRoutines.contains('shoulders_back')) {
        _exerciseNames['military_press'] = 'Standing Military Press';
        _exerciseNames['upright_row'] = 'Dumbbell Upright Row';
        _exerciseNames['shrug'] = 'Dumbbell Shrug';
        _exerciseNames['rear_flye'] = 'Bent-Over Rear Delt Flye';
      }
      if (_selectedRoutines.contains('legs')) {
        _exerciseNames['goblet_squat'] = 'Goblet Squat';
        _exerciseNames['romanian_deadlift'] = 'Romanian Deadlift';
        _exerciseNames['split_squat'] = 'Bulgarian Split Squat';
        _exerciseNames['calf_raise'] = 'Standing Calf Raise';
      }

      _exerciseNames.keys.forEach((key) {
        final weightKg = weights.getWeightForExercise(key);
        final displayWeight = _isMetric ? weightKg : weightKg * 2.20462;
        String str = displayWeight.toStringAsFixed(1);
        if (str.endsWith('.0')) str = str.substring(0, str.length - 2);
        _controllers[key] = TextEditingController(text: str);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final newWeightsKg = <String, double>{};
    _controllers.forEach((key, controller) {
      final val = double.tryParse(controller.text) ?? 8.0;
      newWeightsKg[key] = WeightConverter.displayToKg(val, _isMetric);
    });

    context.read<WorkoutCubit>().updateExerciseWeights(newWeightsKg);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Update Exercise Weights', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Change your current working weights for each exercise. These will take effect on your next set.',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ..._exerciseNames.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(entry.value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _controllers[entry.key],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            suffixText: _isMetric ? 'kg' : 'lbs',
                            suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SAVE WEIGHTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}
