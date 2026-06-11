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
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
}
