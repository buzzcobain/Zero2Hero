import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../../infrastructure/ad_service.dart';

class RestTimerView extends StatelessWidget {
  const RestTimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutCubit, WorkoutState>(
      listenWhen: (previous, current) => previous.isTimerActive && !current.isTimerActive,
      listener: (context, state) {
        // When timer is no longer active (hits 0), automatically dismiss this overlay
        Navigator.of(context).pop();
      },
      child: BlocBuilder<WorkoutCubit, WorkoutState>(
        builder: (context, state) {
          final progress = state.timerTotal > 0 ? state.timerRemaining / state.timerTotal : 0.0;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Glassmorphism Blur Filter
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: state.timerFlashSignal
                        ? const Color(0xFF00E5FF).withOpacity(0.4) // Cyan Pulse Screen Flash on completion
                        : const Color(0xFF0B0F19).withOpacity(0.85),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      // Floating circular countdown
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'REST & RECOVER',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.white10,
                                    color: state.timerFlashSignal ? const Color(0xFF00E676) : const Color(0xFF7C4DFF),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${state.timerRemaining}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10,
                                            color: const Color(0xFF7C4DFF).withOpacity(0.5),
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'seconds left',
                                      style: TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Manual Skip Button
                      ElevatedButton(
                        onPressed: () {
                          context.read<WorkoutCubit>().forceCloseTimer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        child: const Text(
                          'SKIP REST',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),

                      const Spacer(),

                      // Google AdMob Adaptive Banner Ad anchored at absolute bottom
                      Container(
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: context.read<WorkoutCubit>().adService.getBannerAdWidget(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
