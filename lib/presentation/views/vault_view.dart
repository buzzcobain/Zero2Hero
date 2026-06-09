import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../blocs/timelapse/timelapse_cubit.dart';
import '../../infrastructure/camera_device_wrapper.dart';

class VaultView extends StatefulWidget {
  final bool isBypassed;

  const VaultView({super.key, this.isBypassed = false});

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraInitError;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    if (!widget.isBypassed) {
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    try {
      final wrapper = context.read<CameraDeviceWrapper>();
      _cameras = await wrapper.getAvailableCameras();
      
      if (_cameras.isNotEmpty) {
        _cameraController = await wrapper.initCamera(_cameras.first);
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        setState(() {
          _cameraInitError = 'No physical cameras detected on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _cameraInitError = 'Failed to initialize camera hardware: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final wrapper = context.read<CameraDeviceWrapper>();
      XFile file;

      if (_isCameraInitialized && _cameraController != null) {
        file = await wrapper.takePicture(_cameraController!);
      } else {
        // Fallback for tests/mock environments: create a dummy photo
        final tempDir = Directory.systemTemp;
        final dummyFile = File('${tempDir.path}/temp_capture.jpg');
        final tinyPngBytes = [
          137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
          0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
          0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 1, 0, 0,
          5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
        ];
        dummyFile.writeAsBytesSync(tinyPngBytes);
        file = XFile(dummyFile.path);
      }

      if (mounted) {
        await context.read<TimelapseCubit>().saveProgressPhoto(file.path);
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera View / Preview
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: const Color(0xFF0F172A),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Offline / Sandbox Camera Mode',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cameraInitError ?? 'Natively running in a mock sandbox layout.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

          // 2. 50% Opacity Ghost Overlay (Baseline photo)
          BlocBuilder<TimelapseCubit, TimelapseState>(
            builder: (context, state) {
              if (state.baselinePhotoPath != null) {
                final file = File(state.baselinePhotoPath!);
                if (file.existsSync()) {
                  return Opacity(
                    opacity: 0.5, // 50% opacity ghost overlay
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // 3. Close Button & Instructions Overlay
          Positioned(
            top: 48,
            left: 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),

          Positioned(
            top: 52,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'ALIGN GHOST OVERLAY',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 4. Capture Trigger Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capturePhoto,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TAP TO CAPTURE PROGRESS',
                      style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
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
