import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/onboarding/onboarding_cubit.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _vestWeightController = TextEditingController(text: '20.0');
  bool _useWeightVest = false;
  bool _isMetric = true;
  List<String> _selectedRoutines = ['chest_arms', 'shoulders_back', 'legs'];

  final Map<String, TextEditingController> _exerciseControllers = {
    'floor_press': TextEditingController(text: '8.0'),
    'military_press': TextEditingController(text: '8.0'),
    'supinating_curl': TextEditingController(text: '8.0'),
    'cross_hammer': TextEditingController(text: '8.0'),
    'chair_kickback': TextEditingController(text: '8.0'),
    'upright_row': TextEditingController(text: '8.0'),
    'shrug': TextEditingController(text: '8.0'),
    'rear_flye': TextEditingController(text: '8.0'),
    'goblet_squat': TextEditingController(text: '8.0'),
    'romanian_deadlift': TextEditingController(text: '8.0'),
    'split_squat': TextEditingController(text: '8.0'),
    'calf_raise': TextEditingController(text: '8.0'),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _vestWeightController.dispose();
    for (var controller in _exerciseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                        ).createShader(bounds),
                        child: const Text(
                          'ZERO TO HERO',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Set up your physical baseline & weights',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Physical metrics card
                    _buildSectionHeader('1. PHYSICAL PROFILE'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Unit System', style: TextStyle(color: Colors.white, fontSize: 16)),
                              Row(
                                children: [
                                  Text('lbs', style: TextStyle(color: !_isMetric ? const Color(0xFF00E5FF) : Colors.white54)),
                                  Switch(
                                    value: _isMetric,
                                    onChanged: (val) {
                                      setState(() {
                                        _isMetric = val;
                                      });
                                    },
                                    activeColor: const Color(0xFF00E5FF),
                                  ),
                                  Text('kg', style: TextStyle(color: _isMetric ? const Color(0xFF00E5FF) : Colors.white54)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.person,
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            errorText: state.heightError,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _weightController,
                            label: 'Current Weight',
                            icon: Icons.scale,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            errorText: state.weightError,
                            suffixText: _isMetric ? 'kg' : 'lbs',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.fitness_center, color: Color(0xFF00E5FF)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Use Weighted Vest',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
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
                          if (_useWeightVest) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _vestWeightController,
                              label: 'Weight Vest Weight',
                              icon: Icons.add_moderator,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              errorText: state.vestWeightError,
                              suffixText: _isMetric ? 'kg' : 'lbs',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Target Muscle Groups Card
                    _buildSectionHeader('2. TARGET MUSCLE GROUPS'),
                    const SizedBox(height: 12),
                    if (state.routineError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(state.routineError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildRoutineCheckbox('chest_arms', 'Chest & Arms'),
                          _buildRoutineCheckbox('shoulders_back', 'Shoulders & Upper Back'),
                          _buildRoutineCheckbox('legs', 'Legs & Glutes'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Exercise Starting Weights Card
                    _buildSectionHeader('3. STARTING EXERCISE WEIGHTS'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        children: [
                          if (_selectedRoutines.contains('chest_arms')) ...[
                            _buildWeightInputRow('floor_press', 'Dumbbell Floor Press', state),
                            _buildWeightInputRow('supinating_curl', 'Supinating Bicep Curl', state),
                            _buildWeightInputRow('cross_hammer', 'Cross-Body Hammer Curl', state),
                            _buildWeightInputRow('chair_kickback', 'Dining Chair Kickback', state),
                          ],
                          if (_selectedRoutines.contains('shoulders_back')) ...[
                            _buildWeightInputRow('military_press', 'Standing Military Press', state),
                            _buildWeightInputRow('upright_row', 'Dumbbell Upright Row', state),
                            _buildWeightInputRow('shrug', 'Dumbbell Shrug', state),
                            _buildWeightInputRow('rear_flye', 'Bent-Over Rear Delt Flye', state),
                          ],
                          if (_selectedRoutines.contains('legs')) ...[
                            _buildWeightInputRow('goblet_squat', 'Goblet Squat', state),
                            _buildWeightInputRow('romanian_deadlift', 'Romanian Deadlift', state),
                            _buildWeightInputRow('split_squat', 'Bulgarian Split Squat', state),
                            _buildWeightInputRow('calf_raise', 'Standing Calf Raise', state),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                    else
                      ElevatedButton(
                        onPressed: () {
                          final startingWeights = <String, String>{};
                          _exerciseControllers.forEach((key, controller) {
                            startingWeights[key] = controller.text;
                          });

                          context.read<OnboardingCubit>().saveProfile(
                            nameStr: _nameController.text,
                            heightStr: _heightController.text,
                            weightStr: _weightController.text,
                            useWeightVest: _useWeightVest,
                            vestWeightStr: _vestWeightController.text,
                            exerciseStartingWeights: startingWeights,
                            useMetricSystem: _isMetric,
                            selectedRoutines: _selectedRoutines,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          elevation: ButtonStyleButton.allOrNull(0),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 50),
                            child: const Text(
                              'FINISH CONFIGURATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? errorText,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Colors.white38),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent),
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

  Widget _buildWeightInputRow(String id, String label, OnboardingState state) {
    final controller = _exerciseControllers[id]!;
    final error = state.exerciseErrors[id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  errorText: error != null ? '' : null,
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
  }

  Widget _buildRoutineCheckbox(String id, String label) {
    final isSelected = _selectedRoutines.contains(id);
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: isSelected,
      activeColor: const Color(0xFF00E5FF),
      checkColor: const Color(0xFF0F172A),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
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
