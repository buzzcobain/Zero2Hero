import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'infrastructure/ad_service.dart';
import 'infrastructure/camera_device_wrapper.dart';
import 'presentation/blocs/onboarding/onboarding_cubit.dart';
import 'presentation/blocs/workout/workout_cubit.dart';
import 'presentation/blocs/timelapse/timelapse_cubit.dart';
import 'presentation/views/onboarding_view.dart';
import 'presentation/views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final adService = AdmobService();
  await adService.initialize();

  runApp(
    MyApp(
      profileRepository: ProfileRepository(),
      workoutRepository: WorkoutRepository(),
      adService: adService,
      cameraDeviceWrapper: RealCameraDeviceWrapper(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ProfileRepository profileRepository;
  final WorkoutRepository workoutRepository;
  final AdServiceInterface adService;
  final CameraDeviceWrapper cameraDeviceWrapper;

  const MyApp({
    super.key,
    required this.profileRepository,
    required this.workoutRepository,
    required this.adService,
    required this.cameraDeviceWrapper,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: workoutRepository),
        RepositoryProvider.value(value: adService),
        RepositoryProvider.value(value: cameraDeviceWrapper),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingCubit>(
            create: (context) => OnboardingCubit(profileRepository)..checkProfile(),
          ),
          BlocProvider<WorkoutCubit>(
            create: (context) => WorkoutCubit(
              profileRepository: profileRepository,
              workoutRepository: workoutRepository,
              adService: adService,
            ),
          ),
          BlocProvider<TimelapseCubit>(
            create: (context) => TimelapseCubit(cameraDeviceWrapper),
          ),
        ],
        child: MaterialApp(
          title: 'Zero2Hero Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF00E5FF),
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              secondary: Color(0xFF7C4DFF),
              surface: Color(0xFF161F30),
              background: Color(0xFF0B0F19),
            ),
            useMaterial3: true,
          ),
          home: const AppContainer(),
        ),
      ),
    );
  }
}

class AppContainer extends StatelessWidget {
  const AppContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) => previous.profileExists != current.profileExists && current.profileExists,
      listener: (context, state) {
        // As soon as onboarding profile is successfully created, initialize the workout session
        context.read<WorkoutCubit>().initSession();
      },
      builder: (context, state) {
        if (state.isCheckingProfile) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0F19),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            ),
          );
        }

        if (state.profileExists) {
          // Initialize session once if not already done
          final workoutCubit = context.read<WorkoutCubit>();
          if (workoutCubit.state.activeWorkout == null && !workoutCubit.state.isLoading) {
            workoutCubit.initSession();
          }
          return const DashboardView();
        }

        return const OnboardingView();
      },
    );
  }
}
