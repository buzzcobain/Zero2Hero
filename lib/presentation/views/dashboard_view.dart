import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workout/workout_cubit.dart';
import '../blocs/timelapse/timelapse_cubit.dart';
import 'workout_view.dart';
import 'vault_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _activeTab = 0; // 0 = Workout/Rest, 1 = Timelapse Vault
  Timer? _slideshowTimer;
  int _currentSlideIndex = 0;
  bool _isSlideshowPlaying = false;

  @override
  void initState() {
    super.initState();
    context.read<TimelapseCubit>().loadGallery();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  void _toggleSlideshow(List<String> images) {
    if (images.isEmpty) return;

    if (_isSlideshowPlaying) {
      _slideshowTimer?.cancel();
      setState(() {
        _isSlideshowPlaying = false;
      });
    } else {
      setState(() {
        _isSlideshowPlaying = true;
      });
      // 2 FPS = 500ms intervals
      _slideshowTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          _currentSlideIndex = (_currentSlideIndex + 1) % images.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, workoutState) {
              return Column(
                children: [
                  _buildHeader(workoutState),
                  Expanded(
                    child: _activeTab == 0
                        ? _buildWorkoutTab(workoutState)
                        : _buildTimelapseTab(),
                  ),
                  _buildTabBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WorkoutState workoutState) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WELCOME BACK',
                style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                workoutState.userData != null
                    ? '${workoutState.userData!.profile.currentWeightKg} kg Profile'
                    : 'Fitness Tracker',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (workoutState.userData?.profile.useWeightVest ?? false)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Vest: ${workoutState.userData!.profile.weightVestKg}kg',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTab(WorkoutState workoutState) {
    if (workoutState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
    }

    if (workoutState.isRestDay) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                    ).createShader(bounds),
                    child: const Icon(Icons.nightlight_round, size: 72, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Rest Day',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Next routine scheduled for ${workoutState.nextRoutineDay}. Give your muscles time to recover and grow stronger.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                context.read<WorkoutCubit>().bypassRestDay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF161F30),
                foregroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                ),
              ),
              child: const Text(
                'TRAIN TODAY ANYWAY',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      );
    }

    final workout = workoutState.activeWorkout;
    if (workout == null) {
      return const Center(
        child: Text('Failed to load workout definitions', style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TODAY\'S WORKOUT',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  workout.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${workout.exercises.length} Exercises targeting key muscle groups.',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'EXERCISES LIST',
            style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workout.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workout.exercises[index];
              final target = workoutState.targets[exercise.id];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exercise.focus,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          target != null ? '${target.weightKg} kg' : '8.0 kg',
                          style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          target != null ? '3x${target.targetReps} reps' : '3x10 reps',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutCubit>().startWorkout();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutView()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 56),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'START TRAINING SESSION',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimelapseTab() {
    return BlocBuilder<TimelapseCubit, TimelapseState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }

        final photoCount = state.progressPhotos.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transformation Vault',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$photoCount Photos',
                            style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tracks your progress every Friday. Ensure matching visual alignments with standard ghost overlays.',
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Player section
              if (photoCount == 0)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, color: Colors.white24, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No progress photos yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Friday sessions will capture these.',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else ...[
                // Slideshow loop viewer
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(state.progressPhotos[_currentSlideIndex]),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: Colors.black54,
                          child: Text(
                            'Photo ${_currentSlideIndex + 1} / $photoCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Icon(
                              _isSlideshowPlaying ? Icons.pause : Icons.play_arrow,
                              color: const Color(0xFF00E5FF),
                            ),
                            onPressed: () => _toggleSlideshow(state.progressPhotos),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Compile & Export options
                if (state.isCompiling)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TimelapseCubit>().compileVideo();
                    },
                    icon: const Icon(Icons.movie, color: Colors.white),
                    label: const Text(
                      'COMPILE TIMELAPSE VIDEO',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                
                if (state.videoPath != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Compiled Video Saved Offline:',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          state.videoPath!,
                          style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              // Manual photo button for testing
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VaultView(isBypassed: true),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('MANUAL PROGRESS CAPTURE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF161F30),
                  foregroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: _activeTab == 0 ? const Color(0xFF00E5FF) : Colors.white38,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Training',
                      style: TextStyle(
                        color: _activeTab == 0 ? const Color(0xFF00E5FF) : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_album,
                      color: _activeTab == 1 ? const Color(0xFF00E5FF) : Colors.white38,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Timelapse',
                      style: TextStyle(
                        color: _activeTab == 1 ? const Color(0xFF00E5FF) : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
