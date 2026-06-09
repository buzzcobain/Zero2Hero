import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../infrastructure/camera_device_wrapper.dart';

class TimelapseState {
  final bool isLoading;
  final String? baselinePhotoPath;
  final List<String> progressPhotos;
  final String? videoPath;
  final bool isCompiling;
  final bool? compileSuccess;

  const TimelapseState({
    this.isLoading = false,
    this.baselinePhotoPath,
    this.progressPhotos = const [],
    this.videoPath,
    this.isCompiling = false,
    this.compileSuccess,
  });

  TimelapseState copyWith({
    bool? isLoading,
    String? baselinePhotoPath,
    List<String>? progressPhotos,
    String? videoPath,
    bool? isCompiling,
    bool? compileSuccess,
  }) {
    return TimelapseState(
      isLoading: isLoading ?? this.isLoading,
      baselinePhotoPath: baselinePhotoPath ?? this.baselinePhotoPath,
      progressPhotos: progressPhotos ?? this.progressPhotos,
      videoPath: videoPath ?? this.videoPath,
      isCompiling: isCompiling ?? this.isCompiling,
      compileSuccess: compileSuccess ?? this.compileSuccess,
    );
  }
}

class TimelapseCubit extends Cubit<TimelapseState> {
  final CameraDeviceWrapper _cameraDeviceWrapper;

  TimelapseCubit(this._cameraDeviceWrapper) : super(const TimelapseState());

  Future<Directory> get _photosDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/progress_photos');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<void> loadGallery() async {
    emit(state.copyWith(isLoading: true));
    try {
      final dir = await _photosDirectory;
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.jpeg'))
          .map((f) => f.path)
          .toList()
        ..sort(); // Chronological sort based on path naming (progress_YYYY_MM_DD.jpg)

      String? baseline;
      if (files.isNotEmpty) {
        baseline = files.first;
      }

      // Check if compiled video exists
      final docs = await getApplicationDocumentsDirectory();
      final videoFile = File('${docs.path}/progress_timelapse.mp4');
      String? videoPath;
      if (videoFile.existsSync()) {
        videoPath = videoFile.path;
      }

      emit(state.copyWith(
        isLoading: false,
        progressPhotos: files,
        baselinePhotoPath: baseline,
        videoPath: videoPath,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> saveProgressPhoto(String tempPath, {DateTime? mockDate}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final dir = await _photosDirectory;
      final date = mockDate ?? DateTime.now();
      
      // File naming convention: progress_YYYY_MM_DD.jpg
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final newPath = '${dir.path}/progress_${date.year}_${month}_${day}.jpg';
      
      final tempFile = File(tempPath);
      tempFile.copySync(newPath);

      await loadGallery();
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> compileVideo() async {
    if (state.progressPhotos.isEmpty) return;
    
    emit(state.copyWith(isCompiling: true, compileSuccess: null));
    try {
      final compiledPath = await _cameraDeviceWrapper.compileTimelapse(
        imagePaths: state.progressPhotos,
        outputFilename: 'progress_timelapse.mp4',
        fps: 2.0, // 2 fps as per C. Media Storage Metadata
      );

      emit(state.copyWith(
        isCompiling: false,
        compileSuccess: compiledPath != null,
        videoPath: compiledPath,
      ));
    } catch (e) {
      emit(state.copyWith(isCompiling: false, compileSuccess: false));
    }
  }
}
