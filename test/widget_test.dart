import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zero2hero/main.dart';
import 'package:zero2hero/data/models/user_profile.dart';
import 'package:zero2hero/data/models/workout_definitions.dart';
import 'package:zero2hero/data/models/workout_log.dart';
import 'package:zero2hero/data/repositories/profile_repository.dart';
import 'package:zero2hero/data/repositories/workout_repository.dart';
import 'package:zero2hero/infrastructure/ad_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zero2hero/presentation/views/dashboard_view.dart';
import 'package:zero2hero/presentation/blocs/timelapse/timelapse_cubit.dart';
import 'package:zero2hero/infrastructure/camera_device_wrapper.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}
class MockAdService extends Mock implements AdServiceInterface {}
class MockCameraWrapper extends Mock implements CameraDeviceWrapper {}

class FakePathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;

  @override
  Future<String?> getLibraryPath() async => tempPath;

  @override
  Future<String?> getDownloadsPath() async => tempPath;
}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockWorkoutRepository mockWorkoutRepo;
  late MockAdService mockAdService;
  late MockCameraWrapper mockCameraWrapper;
  late Directory tempDir;

  final profile = UserProfile(
    heightCm: 180,
    currentWeightKg: 80.0,
    useWeightVest: false,
    weightVestKg: 0.0,
  );
  final weights = ExerciseWeights(
    floorPress: 8.0,
    militaryPress: 8.0,
    supinatingCurl: 8.0,
    crossHammer: 8.0,
    chairKickback: 8.0,
    uprightRow: 8.0,
    shrug: 8.0,
    rearFlye: 8.0,
  );
  final userData = UserData(profile: profile, weights: weights);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    mockProfileRepo = MockProfileRepository();
    mockWorkoutRepo = MockWorkoutRepository();
    mockAdService = MockAdService();
    mockCameraWrapper = MockCameraWrapper();

    registerFallbackValue(
      UserData(profile: profile, weights: weights),
    );
    registerFallbackValue(
      WorkoutLog(id: '1', date: DateTime.now(), workoutType: 'A', exercises: [], durationMinutes: 0.0, caloriesBurned: 0.0),
    );

    // Mock responses
    when(() => mockProfileRepo.saveProfile(any())).thenAnswer((_) async => {});
    when(() => mockWorkoutRepo.loadWorkoutLogs()).thenAnswer((_) async => []);
    when(() => mockWorkoutRepo.addWorkoutLog(any())).thenAnswer((_) async => {});
    
    // Mock ad methods
    when(() => mockAdService.initialize()).thenAnswer((_) async => {});
    when(() => mockAdService.loadInterstitialAd()).thenAnswer((_) async => {});
    when(() => mockAdService.getBannerAdWidget()).thenReturn(
      const SizedBox(height: 50, child: Text('Mock Ad Widget')),
    );
    when(() => mockAdService.showInterstitialAd(any())).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0] as Function();
      callback();
      return Future.value();
    });

    // Mock camera methods
    when(() => mockCameraWrapper.getAvailableCameras()).thenAnswer((_) async => []);
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Ignore file locks on Windows
    }
  });

  testWidgets('App starts with Onboarding when profile does not exist', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pump(); // trigger builder/splash load

    // Should find onboarding text fields
    expect(find.text('ZERO TO HERO'), findsOneWidget);
    expect(find.text('Height (cm)'), findsOneWidget);
    expect(find.text('Current Weight (kg)'), findsOneWidget);
    expect(find.text('FINISH CONFIGURATION'), findsOneWidget);
  });

  testWidgets('App transitions to Dashboard when profile exists', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => true);
    when(() => mockProfileRepo.loadProfile()).thenAnswer((_) async => userData);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pumpAndSettle(); // process asynchronous flows

    expect(find.text('WELCOME BACK'), findsOneWidget);
  });

  testWidgets('Workout set checklist ticks and Skip Rest closes overlay', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => true);
    when(() => mockProfileRepo.loadProfile()).thenAnswer((_) async => userData);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pumpAndSettle();

    // Bypass rest day if it is rest day
    if (find.text('Rest Day').evaluate().isNotEmpty) {
      await tester.tap(find.text('TRAIN TODAY ANYWAY'));
      await tester.pumpAndSettle();
    }

    // Start training session
    await tester.ensureVisible(find.text('START TRAINING SESSION'));
    await tester.tap(find.text('START TRAINING SESSION'));
    await tester.pumpAndSettle();

    // Check Set 1 of first exercise
    await tester.ensureVisible(find.text('SET 1').first);
    await tester.tap(find.text('SET 1').first);
    await tester.pump(); // starts timer dialog dialog

    // Dialog contains REST & RECOVER
    expect(find.text('REST & RECOVER'), findsOneWidget);
    expect(find.text('SKIP REST'), findsOneWidget);

    // Click Skip Rest
    await tester.tap(find.text('SKIP REST'));
    await tester.pumpAndSettle();

    // Dialog should be closed, back to workout screen
    expect(find.text('REST & RECOVER'), findsNothing);
  });

  testWidgets('App onboarding form input validations and submission flow', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => false);
    when(() => mockProfileRepo.loadProfile()).thenAnswer((_) async => userData);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pumpAndSettle();

    // 1. Submit with empty form to trigger validations
    await tester.ensureVisible(find.text('FINISH CONFIGURATION'));
    await tester.tap(find.text('FINISH CONFIGURATION'));
    await tester.pumpAndSettle();

    // 2. Fill onboarding form fields
    await tester.enterText(find.byType(TextField).at(0), '178');
    await tester.enterText(find.byType(TextField).at(1), '76.4');
    
    // Toggle weight vest switch
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Fill weight vest weight
    await tester.enterText(find.byType(TextField).at(2), '15.0');
    
    // Submit valid configuration
    await tester.ensureVisible(find.text('FINISH CONFIGURATION'));
    await tester.tap(find.text('FINISH CONFIGURATION'));
    await tester.pumpAndSettle();

    verify(() => mockProfileRepo.saveProfile(any())).called(1);
  });

  testWidgets('Dashboard Timelapse view play slideshow and compile video triggers', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => true);
    when(() => mockProfileRepo.loadProfile()).thenAnswer((_) async => userData);

    // Mock two photos in the directory
    final file1 = File('${tempDir.path}/progress_photos/progress_2026_06_01.jpg');
    final file2 = File('${tempDir.path}/progress_photos/progress_2026_06_08.jpg');
    file1.createSync(recursive: true);
    file2.createSync(recursive: true);
    final tinyPngBytes = [
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 1, 0, 0,
      5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
    ];
    file1.writeAsBytesSync(tinyPngBytes);
    file2.writeAsBytesSync(tinyPngBytes);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Timelapse Tab (which is the second tab)
    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify it loads photos
    expect(find.text('2 Photos'), findsOneWidget);

    // Toggle play/pause slideshow button
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 500));

    // Pause slideshow
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    // Trigger video compiler
    when(() => mockCameraWrapper.compileTimelapse(
          imagePaths: any(named: 'imagePaths'),
          outputFilename: any(named: 'outputFilename'),
          fps: any(named: 'fps'),
        )).thenAnswer((_) async => '${tempDir.path}/progress_timelapse.mp4');

    await tester.ensureVisible(find.text('COMPILE TIMELAPSE VIDEO'));
    await tester.tap(find.text('COMPILE TIMELAPSE VIDEO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    verify(() => mockCameraWrapper.compileTimelapse(
          imagePaths: any(named: 'imagePaths'),
          outputFilename: 'progress_timelapse.mp4',
          fps: 2.0,
        )).called(1);

    // Click Manual capture to verify routing
    await tester.ensureVisible(find.text('MANUAL PROGRESS CAPTURE'));
    await tester.tap(find.text('MANUAL PROGRESS CAPTURE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Displays mock camera sandbox layout
    expect(find.text('Offline / Sandbox Camera Mode'), findsOneWidget);

    // Capture photo
    await tester.tap(find.text('TAP TO CAPTURE PROGRESS'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Navigated back to dashboard
    expect(find.text('Offline / Sandbox Camera Mode'), findsNothing);
  });

  testWidgets('Workout session completion flow triggers summary view and dashboard routing', (WidgetTester tester) async {
    when(() => mockProfileRepo.profileExists()).thenAnswer((_) async => true);
    when(() => mockProfileRepo.loadProfile()).thenAnswer((_) async => userData);

    await tester.pumpWidget(
      MyApp(
        profileRepository: mockProfileRepo,
        workoutRepository: mockWorkoutRepo,
        adService: mockAdService,
        cameraDeviceWrapper: mockCameraWrapper,
      ),
    );

    await tester.pumpAndSettle();

    // Bypass rest day if it is rest day
    if (find.text('Rest Day').evaluate().isNotEmpty) {
      await tester.tap(find.text('TRAIN TODAY ANYWAY'));
      await tester.pumpAndSettle();
    }

    // Start training session
    await tester.ensureVisible(find.text('START TRAINING SESSION'));
    await tester.tap(find.text('START TRAINING SESSION'));
    await tester.pumpAndSettle();

    // Complete all 3 sets for each of the 4 exercises in Workout A
    final exercises = [
      'Dumbbell Floor Press',
      'Supinating Bicep Curl',
      'Cross-Body Hammer Curl',
      'Dining Chair Kickback',
    ];

    for (var name in exercises) {
      final exerciseFinder = find.text(name);
      await tester.ensureVisible(exerciseFinder);
      await tester.pumpAndSettle();

      final exerciseContainer = find.ancestor(
        of: exerciseFinder,
        matching: find.byType(Container),
      ).first;

      for (int setIndex = 1; setIndex <= 3; setIndex++) {
        final setFinder = find.descendant(
          of: exerciseContainer,
          matching: find.text('SET $setIndex'),
        );
        await tester.ensureVisible(setFinder);
        await tester.tap(setFinder);
        await tester.pump();
        
        // Skip rest dialog if active
        if (find.text('SKIP REST').evaluate().isNotEmpty) {
          await tester.tap(find.text('SKIP REST').first);
          await tester.pumpAndSettle();
        }
      }
    }

    // Summary view should be displayed
    expect(find.text('SESSION COMPLETE'), findsOneWidget);
    expect(find.text('BACK TO DASHBOARD'), findsOneWidget);

    // Tap BACK TO DASHBOARD
    await tester.tap(find.text('BACK TO DASHBOARD'));
    await tester.pumpAndSettle();

    // Back on dashboard
    expect(find.text('WELCOME BACK'), findsOneWidget);
  });
}
