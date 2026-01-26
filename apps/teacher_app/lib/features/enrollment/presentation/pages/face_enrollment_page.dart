import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../../shared/data/services/camera_service.dart';
import '../../../../shared/data/services/cv_service_mock.dart';

/// Page for enrolling students with face recognition (multi-pose capture)
class FaceEnrollmentPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const FaceEnrollmentPage({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  final _cameraService = CameraService();
  final _cvService = CVServiceMock();
  
  bool _isCameraInitialized = false;
  int _currentPoseIndex = 0;
  int _totalPoses = 3;  // Simplified to 3 poses
  List<Uint8List> _capturedImages = [];
  bool _isProcessing = false;
  bool _enrollmentComplete = false;
  String? _error;

  final List<String> _poseInstructions = [
    'Look straight ahead',
    'Turn head to the right',
    'Turn head to the left',
    'Look up slightly',
    'Look down slightly',
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _cameraService.initialize();
      await _cvService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _captureFace() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Simulate camera capture and face detection
      final faces = await _cvService.detectFaces(Uint8List(0));

      if (!mounted) return;

      if (faces.isEmpty) {
        _showError('No face detected. Please try again.');
        setState(() => _isProcessing = false);
        return;
      }

      // Simulate storing a captured image
      _capturedImages.add(Uint8List(100));  // Mock image data

      // Show success feedback
      _showSuccess(
        'Pose ${_currentPoseIndex + 1}/$_totalPoses captured!',
      );

      // If this is the last pose, enroll the student
      if (_currentPoseIndex == _totalPoses - 1) {
        await _enrollStudent();
      } else {
        // Move to next pose
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          setState(() => _currentPoseIndex++);
        }
      }
    } catch (e) {
      _showError('Failed to capture face: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _enrollStudent() async {
    if (!mounted) return;

    try {
      // Extract embedding from first captured image
      final embedding = await _cvService.extractEmbedding(Uint8List(100));
      
      if (embedding != null) {
        // Store face template for this student
        await _cvService.storeFaceTemplate(widget.studentId, embedding);
        
        setState(() {
          _enrollmentComplete = true;
        });
        
        _showSuccess('Enrollment successful!');
        
        // Return to enrollment list after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      _showError('Enrollment failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetEnrollment() {
    setState(() {
      _currentPoseIndex = 0;
      _capturedImages.clear();
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_enrollmentComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Enroll ${widget.studentName}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text('Enrollment Successful!'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Enroll ${widget.studentName}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Enroll ${widget.studentName}'),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPoseIndex + 1) / _totalPoses,
            minHeight: 4,
          ),
          // Camera simulation
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera, size: 80, color: Colors.grey[600]),
                    const SizedBox(height: 20),
                    Text(
                      'Pose ${_currentPoseIndex + 1} of $_totalPoses',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _poseInstructions[_currentPoseIndex],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureFace,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _resetEnrollment,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

