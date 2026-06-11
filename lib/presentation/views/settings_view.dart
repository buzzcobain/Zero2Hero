import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../blocs/onboarding/onboarding_cubit.dart';
import '../../../data/repositories/profile_repository.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocBuilder<WorkoutCubit, WorkoutState>(
        builder: (context, state) {
          final isMetric = state.userData?.profile.useMetricSystem ?? true;
          final schedule = state.userData?.profile.workoutSchedule ?? {'1': '07:00', '3': '07:00', '5': '07:00'};
          final enableNotifs = state.userData?.profile.enableNotifications ?? true;
          final offsetMins = state.userData?.profile.notificationOffsetMinutes ?? 10;
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('GENERAL', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use Metric System', style: TextStyle(color: Colors.white)),
                subtitle: Text(isMetric ? 'Weights shown in kg' : 'Weights shown in lbs', style: const TextStyle(color: Colors.white54)),
                value: isMetric,
                activeColor: const Color(0xFF00E5FF),
                tileColor: const Color(0xFF161F30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white10),
                ),
                onChanged: (val) {
                  context.read<WorkoutCubit>().toggleMetricSystem(val);
                },
              ),
              const SizedBox(height: 32),
              
              const Text('WORKOUT SCHEDULE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Reminders', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Receive notifications for workouts', style: TextStyle(color: Colors.white54)),
                      value: enableNotifs,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) {
                        context.read<WorkoutCubit>().updateWorkoutSchedule(schedule, val, offsetMins);
                      },
                    ),
                    if (enableNotifs) ...[
                      const Divider(color: Colors.white10, height: 1),
                      ListTile(
                        title: const Text('Remind me before', style: TextStyle(color: Colors.white)),
                        trailing: DropdownButton<int>(
                          dropdownColor: const Color(0xFF161F30),
                          value: offsetMins,
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
                              context.read<WorkoutCubit>().updateWorkoutSchedule(schedule, enableNotifs, val);
                            }
                          },
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: List.generate(7, (index) {
                    final dayInt = index + 1;
                    final dayString = dayInt.toString();
                    final isEnabled = schedule.containsKey(dayString);
                    final timeString = isEnabled ? schedule[dayString]! : '07:00';
                    
                    return Column(
                      children: [
                        ListTile(
                          title: Text(_getWeekdayName(dayInt), style: TextStyle(color: isEnabled ? Colors.white : Colors.white54)),
                          leading: Checkbox(
                            value: isEnabled,
                            activeColor: const Color(0xFF00E5FF),
                            onChanged: (val) {
                              final newSchedule = Map<String, String>.from(schedule);
                              if (val == true) {
                                newSchedule[dayString] = '07:00';
                              } else {
                                newSchedule.remove(dayString);
                              }
                              context.read<WorkoutCubit>().updateWorkoutSchedule(newSchedule, enableNotifs, offsetMins);
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
                                      final newSchedule = Map<String, String>.from(schedule);
                                      final h = newTime.hour.toString().padLeft(2, '0');
                                      final m = newTime.minute.toString().padLeft(2, '0');
                                      newSchedule[dayString] = '$h:$m';
                                      context.read<WorkoutCubit>().updateWorkoutSchedule(newSchedule, enableNotifs, offsetMins);
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
                ),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF161F30),
                        title: const Text('Clear Profile?', style: TextStyle(color: Colors.white)),
                        content: const Text('This will reset your weights and setup data. Are you sure?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await context.read<ProfileRepository>().clearProfile();
                      if (context.mounted) {
                        context.read<OnboardingCubit>().checkProfile();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text('Clear Profile Settings', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
