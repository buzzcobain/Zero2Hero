import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zero2hero/infrastructure/camera_device_wrapper.dart';
import 'package:zero2hero/presentation/blocs/timelapse/timelapse_cubit.dart';

class MockCameraDeviceWrapper extends Mock implements CameraDeviceWrapper {}

// A mock Path Provider platform implementation so that getApplicationDocumentsDirectory()
// returns a valid temporary path during unit tests instead of throwing a MissingPluginException.
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCameraDeviceWrapper mockCameraDeviceWrapper;
  late TimelapseCubit timelapseCubit;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    mockCameraDeviceWrapper = MockCameraDeviceWrapper();
    timelapseCubit = TimelapseCubit(mockCameraDeviceWrapper);

    registerFallbackValue(const Duration());
  });

  tearDown(() {
    timelapseCubit.close();
    tempDir.deleteSync(recursive: true);
  });

  group('TimelapseCubit Tests', () {
    test('loadGallery handles empty folder', () async {
      await timelapseCubit.loadGallery();

      expect(timelapseCubit.state.progressPhotos, isEmpty);
      expect(timelapseCubit.state.baselinePhotoPath, isNull);
      expect(timelapseCubit.state.videoPath, isNull);
    });

    test('saveProgressPhoto stores photo with name and sets baseline', () async {
      final dummySource = File('${tempDir.path}/temp_source.jpg')..writeAsStringSync('raw content');

      final date = DateTime(2026, 6, 12); // Friday
      await timelapseCubit.saveProgressPhoto(dummySource.path, mockDate: date);

      expect(timelapseCubit.state.progressPhotos.length, 1);
      expect(
        timelapseCubit.state.progressPhotos.first,
        contains('progress_2026_06_12.jpg'),
      );
      expect(timelapseCubit.state.baselinePhotoPath, isNotNull);
    });

    test('compileVideo runs FFmpeg pipeline', () async {
      // Setup some photos in gallery first
      final dummySource = File('${tempDir.path}/temp_source.jpg')..writeAsStringSync('raw content');
      await timelapseCubit.saveProgressPhoto(dummySource.path, mockDate: DateTime(2026, 6, 12));

      when(() => mockCameraDeviceWrapper.compileTimelapse(
            imagePaths: any(named: 'imagePaths'),
            outputFilename: any(named: 'outputFilename'),
            fps: any(named: 'fps'),
          )).thenAnswer((_) async => '${tempDir.path}/progress_timelapse.mp4');

      await timelapseCubit.compileVideo();

      expect(timelapseCubit.state.isCompiling, isFalse);
      expect(timelapseCubit.state.compileSuccess, isTrue);
      expect(timelapseCubit.state.videoPath, contains('progress_timelapse.mp4'));
      
      verify(() => mockCameraDeviceWrapper.compileTimelapse(
            imagePaths: any(named: 'imagePaths'),
            outputFilename: 'progress_timelapse.mp4',
            fps: 2.0,
          )).called(1);
    });
  });
}
