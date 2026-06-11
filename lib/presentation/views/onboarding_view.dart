import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/onboarding/onboarding_cubit.dart';
import '../widgets/scroll_indicator_wrapper.dart';

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
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _weightStController = TextEditingController();
  final _weightLbsController = TextEditingController();
  final _vestWeightStController = TextEditingController(text: '3');
  final _vestWeightLbsController = TextEditingController(text: '2');
  
  bool _useWeightVest = false;
  bool _isMetric = true;
  List<String> _selectedRoutines = ['chest_arms', 'shoulders_back', 'legs'];

  Map<String, String> _schedule = {'1': '07:00', '3': '07:00', '5': '07:00'};
  bool _enableNotifications = true;
  int _notificationOffsetMinutes = 10;

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
    _heightFtController.dispose();
    _heightInController.dispose();
    _weightStController.dispose();
    _weightLbsController.dispose();
    _vestWeightStController.dispose();
    _vestWeightLbsController.dispose();
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
              return ScrollIndicatorWrapper(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          if (_isMetric) ...[
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
                              suffixText: 'kg',
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildTextField(controller: _heightFtController, label: 'Height (ft)', icon: Icons.height, keyboardType: TextInputType.number, errorText: state.heightError)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(controller: _heightInController, label: 'Height (in)', icon: Icons.height, keyboardType: TextInputType.number, errorText: state.heightError == null ? null : '')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildTextField(controller: _weightStController, label: 'Weight (st)', icon: Icons.scale, keyboardType: const TextInputType.numberWithOptions(decimal: true), errorText: state.weightError)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(controller: _weightLbsController, label: 'Weight (lbs)', icon: Icons.scale, keyboardType: const TextInputType.numberWithOptions(decimal: true), errorText: state.weightError == null ? null : '')),
                              ],
                            ),
                          ],
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
                            if (_isMetric)
                              _buildTextField(
                                controller: _vestWeightController,
                                label: 'Weight Vest Weight',
                                icon: Icons.add_moderator,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                errorText: state.vestWeightError,
                                suffixText: 'kg',
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTextField(controller: _vestWeightStController, label: 'Vest (st)', icon: Icons.add_moderator, keyboardType: const TextInputType.numberWithOptions(decimal: true), errorText: state.vestWeightError)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildTextField(controller: _vestWeightLbsController, label: 'Vest (lbs)', icon: Icons.add_moderator, keyboardType: const TextInputType.numberWithOptions(decimal: true), errorText: state.vestWeightError == null ? null : '')),
                                ],
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

                    const SizedBox(height: 28),

                    // Workout Schedule Card
                    _buildSectionHeader('4. WORKOUT SCHEDULE'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Reminders', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Receive notifications for workouts', style: TextStyle(color: Colors.white54)),
                            value: _enableNotifications,
                            activeColor: const Color(0xFF00E5FF),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                _enableNotifications = val;
                              });
                            },
                          ),
                          if (_enableNotifications) ...[
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Remind me before', style: TextStyle(color: Colors.white)),
                              trailing: DropdownButton<int>(
                                dropdownColor: const Color(0xFF161F30),
                                value: _notificationOffsetMinutes,
                                style: const TextStyle(color: Colors.white),
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('At exact time')),
                                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _notificationOffsetMinutes = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ...List.generate(7, (index) {
                            final dayInt = index + 1;
                            final dayString = dayInt.toString();
                            final isEnabled = _schedule.containsKey(dayString);
                            final timeString = isEnabled ? _schedule[dayString]! : '07:00';
                            
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_getWeekdayName(dayInt), style: TextStyle(color: isEnabled ? Colors.white : Colors.white54)),
                                  leading: Checkbox(
                                    value: isEnabled,
                                    activeColor: const Color(0xFF00E5FF),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _schedule[dayString] = '07:00';
                                        } else {
                                          _schedule.remove(dayString);
                                        }
                                      });
                                    },
                                  ),
                                  trailing: isEnabled
                                      ? TextButton(
                                          onPressed: () async {
                                            final parts = timeString.split(':');
                                            final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                                            final newTime = await showTimePicker(
                                              context: context,
                                              initialTime: initialTime,
                                              builder: (context, child) {
                                                return Theme(
                                                  data: ThemeData.dark().copyWith(
                                                    colorScheme: const ColorScheme.dark(
                                                      primary: Color(0xFF00E5FF),
                                                      onPrimary: Colors.black,
                                                      surface: Color(0xFF161F30),
                                                      onSurface: Colors.white,
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (newTime != null && context.mounted) {
                                              setState(() {
                                                final h = newTime.hour.toString().padLeft(2, '0');
                                                final m = newTime.minute.toString().padLeft(2, '0');
                                                _schedule[dayString] = '$h:$m';
                                              });
                                            }
                                          },
                                          child: Text(timeString, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
                                        )
                                      : null,
                                ),
                                if (index < 6) const Divider(color: Colors.white10, height: 1),
                              ],
                            );
                          }),
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
                            heightFtStr: _heightFtController.text,
                            heightInStr: _heightInController.text,
                            weightStr: _weightController.text,
                            weightStStr: _weightStController.text,
                            weightLbsStr: _weightLbsController.text,
                            useWeightVest: _useWeightVest,
                            vestWeightStr: _vestWeightController.text,
                            vestWeightStStr: _vestWeightStController.text,
                            vestWeightLbsStr: _vestWeightLbsController.text,
                            exerciseStartingWeights: startingWeights,
                            useMetricSystem: _isMetric,
                            selectedRoutines: _selectedRoutines,
                            workoutSchedule: _schedule,
                            enableNotifications: _enableNotifications,
                            notificationOffsetMinutes: _notificationOffsetMinutes,
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

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
