import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../../utils/weight_converter.dart';
import 'rest_timer_view.dart';
import 'vault_view.dart';

class WorkoutView extends StatelessWidget {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutCubit, WorkoutState>(
      listenWhen: (previous, current) => previous.isTimerActive != current.isTimerActive || previous.isWorkoutFinished != current.isWorkoutFinished,
      listener: (context, state) {
        if (state.isTimerActive) {
          // Open the Rest Timer Screen overlay
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierLabel: 'Rest Timer',
            pageBuilder: (context, animation, secondaryAnimation) {
              return const RestTimerView();
            },
          );
        }
      },
      builder: (context, state) {
        if (state.isWorkoutFinished) {
          return _buildSummaryView(context, state);
        }

        final workout = state.activeWorkout;
        if (workout == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0F19),
            body: Center(child: Text('No active workout', style: TextStyle(color: Colors.white))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              workout.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              itemCount: workout.exercises.length,
              itemBuilder: (context, index) {
                final isMetric = state.userData?.profile.useMetricSystem ?? true;
                final exercise = workout.exercises[index];
                final target = state.targets[exercise.id];
                final setsCompleted = state.completedSets[exercise.id] ?? [false, false, false];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'assets/images/exercises/${exercise.id}.gif',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'assets/images/exercises/${exercise.id}.gif',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.white10,
                                        child: const Icon(Icons.fitness_center, color: Colors.white24),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exercise.focus,
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              target != null ? WeightConverter.format(target.weightKg, isMetric) : WeightConverter.format(8.0, isMetric),
                              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(3, (setIdx) {
                          final isCompleted = setsCompleted[setIdx];
                          return _buildSetCheckbox(
                            context: context,
                            exerciseId: exercise.id,
                            setNumber: setIdx + 1,
                            isCompleted: isCompleted,
                            onTap: () {
                              context.read<WorkoutCubit>().toggleSet(exercise.id, setIdx);
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetCheckbox({
    required BuildContext context,
    required String exerciseId,
    required int setNumber,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF00E676).withOpacity(0.15) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF00E676) : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              'SET $setNumber',
              style: TextStyle(
                color: isCompleted ? const Color(0xFF00E676) : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_off,
              color: isCompleted ? const Color(0xFF00E676) : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context, WorkoutState state) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF00E676),
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'SESSION COMPLETE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Great job completing your workout!',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),

                // Metrics cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                            const SizedBox(height: 10),
                            const Text('CALORIES BURNED', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text(
                              '${state.caloriesBurned.toStringAsFixed(1)} kcal',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.celebration, color: Color(0xFF00E5FF), size: 28),
                            const SizedBox(height: 10),
                            const Text('WORKOUT STATUS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text(
                              state.triggerCameraVault ? 'Friday Capture' : 'Completed',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (state.weeklyStats != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'WEEKLY SUMMARY',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('THIS WEEK', '${state.weeklyStats!.repsThisWeek}', 'reps'),
                            _buildStatItem('THIS MONTH', '${state.weeklyStats!.repsThisMonth}', 'reps'),
                            _buildStatItem('ALL TIME', '${state.weeklyStats!.repsTotal}', 'reps'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),
                        Text(
                          'You have lifted a total of ${state.weeklyStats!.weightTotalKg.toInt()} kg!',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'That\'s equivalent to a ${state.weeklyStats!.animalEquivalent} ${state.weeklyStats!.animalEmoji}',
                          style: const TextStyle(color: Color(0xFF00E676), fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Conditional Friday Vault Intercept
                if (state.triggerCameraVault) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Friday Transformation Vault',
                          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'You must take your week-over-week progress photo to finalize today\'s session logs!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const VaultView()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('OPEN PHOTO INTERCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF161F30),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                    ),
                    child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }
}
