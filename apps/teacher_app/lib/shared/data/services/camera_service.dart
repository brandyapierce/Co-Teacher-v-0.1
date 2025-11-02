import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Service for managing camera operations including preview and capture
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the camera service with available cameras
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException(
          'noCamerasAvailable',
          'No cameras found on this device',
        );
      }
      
      // Use the first available camera (usually front camera)
      final camera = _cameras!.first;
      
      // Initialize controller with medium resolution for better performance
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      rethrow;
    }
  }
  
  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw CameraException(
        'insufficientCameras',
        'Cannot switch camera - only one camera available',
      );
    }
    
    final currentCamera = _controller?.description;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != currentCamera?.lensDirection,
      orElse: () => _cameras!.first,
    );
    
    await _controller?.dispose();
    
    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    await _controller!.initialize();
  }
  
  /// Capture an image from the camera
  Future<Uint8List> captureImage() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      throw CameraException(
        'cameraNotInitialized',
        'Camera must be initialized before capturing',
      );
    }
    
    try {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      return bytes;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      rethrow;
    }
  }
  
  /// Start camera preview (controller must be passed to CameraPreview widget)
  Future<void> startPreview() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Pause camera preview
  Future<void> pausePreview() async {
    // On some platforms, we may want to pause the camera
    // For now, this is a no-op as Flutter camera handles this automatically
  }
  
  /// Resume camera preview
  Future<void> resumePreview() async {
    if (_controller != null && !_controller!.value.isInitialized) {
      await _controller!.initialize();
    }
  }
  
  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
  
  /// Get camera aspect ratio for UI layout
  double get aspectRatio {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0; // Default square
    }
    return _controller!.value.aspectRatio;
  }
  
  /// Check if flash is available
  bool get hasFlash {
    return _controller?.description.lensDirection == CameraLensDirection.back;
  }
  
  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setFlashMode(mode);
    }
  }
}

