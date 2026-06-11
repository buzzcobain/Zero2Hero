import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../../utils/weight_converter.dart';

class UpdateProfileView extends StatefulWidget {
  const UpdateProfileView({super.key});

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final _weightController = TextEditingController();
  final _vestWeightController = TextEditingController();
  bool _useWeightVest = false;
  bool _isMetric = true;
  List<String> _selectedRoutines = ['chest_arms', 'shoulders_back', 'legs'];

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkoutCubit>().state;
    if (state.userData != null) {
      final profile = state.userData!.profile;
      _isMetric = profile.useMetricSystem;
      _weightController.text = _isMetric ? profile.currentWeightKg.toStringAsFixed(1) : (profile.currentWeightKg * 2.20462).toStringAsFixed(1);
      _vestWeightController.text = _isMetric ? profile.weightVestKg.toStringAsFixed(1) : (profile.weightVestKg * 2.20462).toStringAsFixed(1);
      _useWeightVest = profile.useWeightVest;
      _selectedRoutines = List.from(profile.selectedRoutines);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _vestWeightController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one routine')));
      return;
    }
    
    final weight = double.tryParse(_weightController.text) ?? 70.0;
    final vestWeight = double.tryParse(_vestWeightController.text) ?? 20.0;
    
    final weightKg = WeightConverter.displayToKg(weight, _isMetric);
    final vestWeightKg = WeightConverter.displayToKg(vestWeight, _isMetric);

    context.read<WorkoutCubit>().updateBodyProfile(weightKg, _useWeightVest, vestWeightKg);
    context.read<WorkoutCubit>().updateSelectedRoutines(_selectedRoutines);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Update Body Weight', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTextField(
              controller: _weightController,
              label: 'Current Weight',
              icon: Icons.scale,
              suffixText: _isMetric ? 'kg' : 'lbs',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fitness_center, color: Color(0xFF00E5FF)),
                      SizedBox(width: 12),
                      Text('Use Weighted Vest', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Switch(
                    value: _useWeightVest,
                    onChanged: (val) {
                      setState(() {
                        _useWeightVest = val;
                      });
                    },
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
            if (_useWeightVest) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _vestWeightController,
                label: 'Weight Vest Weight',
                icon: Icons.add_moderator,
                suffixText: _isMetric ? 'kg' : 'lbs',
              ),
            ],
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('TARGET MUSCLE GROUPS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildRoutineCheckbox('chest_arms', 'Chest & Arms'),
                  _buildRoutineCheckbox('shoulders_back', 'Shoulders & Upper Back'),
                  _buildRoutineCheckbox('legs', 'Legs & Glutes'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildRoutineCheckbox(String id, String label) {
    final isSelected = _selectedRoutines.contains(id);
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: isSelected,
      activeColor: const Color(0xFF00E5FF),
      checkColor: const Color(0xFF0F172A),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedRoutines.add(id);
          } else {
            _selectedRoutines.remove(id);
          }
        });
      },
    );
  }
}
