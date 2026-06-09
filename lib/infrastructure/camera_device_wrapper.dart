import 'dart:io';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

abstract class CameraDeviceWrapper {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initCamera(CameraDescription camera);
  Future<XFile> takePicture(CameraController controller);
  Future<String?> compileTimelapse({
    required List<String> imagePaths,
    required String outputFilename,
    required double fps,
  });
}

class RealCameraDeviceWrapper implements CameraDeviceWrapper {
  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  @override
  Future<CameraController> initCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }

  @override
  Future<XFile> takePicture(CameraController controller) async {
    return await controller.takePicture();
  }

  @override
  Future<String?> compileTimelapse({
    required List<String> imagePaths,
    required String outputFilename,
    required double fps,
  }) async {
    if (imagePaths.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final txtFile = File('${tempDir.path}/images_list.txt');

    final sink = txtFile.openWrite();
    final duration = 1.0 / fps;
    for (var i = 0; i < imagePaths.length; i++) {
      sink.writeln("file '${imagePaths[i]}'");
      sink.writeln("duration $duration");
    }
    // Duplicate last file because FFmpeg concat requires duration on all but the last
    sink.writeln("file '${imagePaths.last}'");
    await sink.close();

    final docsDir = await getApplicationDocumentsDirectory();
    final outputPath = '${docsDir.path}/$outputFilename';

    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final cmd = "-y -f concat -safe 0 -i ${txtFile.path} -c:v mpeg4 -pix_fmt yuv420p $outputPath";

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      return null;
    }
  }
}

class MockCameraDeviceWrapper implements CameraDeviceWrapper {
  final List<CameraDescription> mockCameras;

  MockCameraDeviceWrapper({List<CameraDescription>? cameras})
      : mockCameras = cameras ?? [];

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return mockCameras;
  }

  @override
  Future<CameraController> initCamera(CameraDescription camera) async {
    throw UnimplementedError("CameraController cannot be initialized on mock desktop/test environments.");
  }

  @override
  Future<XFile> takePicture(CameraController controller) async {
    return XFile('mock_photo.jpg');
  }

  @override
  Future<String?> compileTimelapse({
    required List<String> imagePaths,
    required String outputFilename,
    required double fps,
  }) async {
    if (imagePaths.isEmpty) return null;
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/$outputFilename';
    final mockFile = File(outputPath);
    await mockFile.writeAsString("mock video data content");
    return outputPath;
  }
}
