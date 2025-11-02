import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../../shared/data/services/camera_service.dart';
// Using mock CV service for now due to TFLite Windows compilation issues
import '../../../../shared/data/services/cv_service_mock.dart';
import '../../../../shared/presentation/widgets/camera_preview_widget.dart';

/// Page for enrolling students with face recognition (3-5 poses)
class FaceEnrollmentPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  
  const FaceEnrollmentPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  final CameraService _cameraService = CameraService();
  final CVServiceMock _cvService = CVServiceMock();
  
  final List<Uint8List> _capturedPoses = [];
  final List<String> _poseInstructions = [
    'Look straight at the camera',
    'Turn your head slightly left',
    'Turn your head slightly right',
    'Tilt your head down slightly',
    'Smile naturally',
  ];
  
  int _currentPoseIndex = 0;
  bool _isProcessing = false;
  bool _enrollmentComplete = false;
  String? _error;
  
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
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
  
  Future<void> _captureCurrentPose() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    
    try {
      // Capture image from camera
      final imageBytes = await _cameraService.captureImage();
      
      // Detect faces in the image
      final faces = await _cvService.detectFaces(imageBytes);
      
      if (faces.isEmpty) {
        setState(() {
          _error = 'No face detected. Please ensure your face is visible.';
          _isProcessing = false;
        });
        return;
      }
      
      if (faces.length > 1) {
        setState(() {
          _error = 'Multiple faces detected. Please ensure only one person is in frame.';
          _isProcessing = false;
        });
        return;
      }
      
      // Face detected successfully
      _capturedPoses.add(imageBytes);
      
      // Extract embedding and store/update template
      final face = faces.first;
      final embedding = await _cvService.extractEmbedding(
        imageBytes,
        face.boundingBox,
      );
      
      if (_currentPoseIndex == 0) {
        // First pose - create new template
        await _cvService.storeFaceTemplate(
          widget.studentId,
          embedding,
          poseCount: 1,
        );
      } else {
        // Additional pose - update template (averaging)
        await _cvService.updateFaceTemplate(
          widget.studentId,
          embedding,
        );
      }
      
      // Move to next pose or complete
      if (_currentPoseIndex < _poseInstructions.length - 1) {
        setState(() {
          _currentPoseIndex++;
          _isProcessing = false;
        });
      } else {
        // Enrollment complete!
        setState(() {
          _enrollmentComplete = true;
          _isProcessing = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
  
  void _retryCurrentPose() {
    if (_capturedPoses.isNotEmpty) {
      setState(() {
        _capturedPoses.removeLast();
        if (_currentPoseIndex > 0) {
          _currentPoseIndex--;
        }
        _error = null;
      });
    }
  }
  
  @override
  void dispose() {
    _cameraService.dispose();
    // Don't dispose CV service as it's shared
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_enrollmentComplete) {
      return _buildCompletionScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          
          // Instructions
          _buildInstructions(),
          
          // Camera preview
          Expanded(
            child: CameraPreviewWidget(
              cameraService: _cameraService,
              onCapture: _isProcessing ? null : _captureCurrentPose,
              showControls: true,
            ),
          ),
          
          // Captured poses thumbnails
          _buildCapturedPosesThumbnails(),
          
          // Error message
          if (_error != null) _buildErrorMessage(),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar() {
    final progress = (_currentPoseIndex + 1) / _poseInstructions.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student: ${widget.studentName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentPoseIndex + 1}/${_poseInstructions.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _poseInstructions[_currentPoseIndex],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCapturedPosesThumbnails() {
    if (_capturedPoses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedPoses.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _capturedPoses[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Retry button
          if (_capturedPoses.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _retryCurrentPose,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          
          // Skip button (for poses 4-5 which are optional)
          if (_currentPoseIndex >= 3)
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : () {
                setState(() {
                  _enrollmentComplete = true;
                });
              },
              icon: const Icon(Icons.skip_next),
              label: const Text('Complete'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Complete'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enrollment Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.studentName} has been enrolled with ${_capturedPoses.length} poses.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.done),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _enrollmentComplete = false;
                    _capturedPoses.clear();
                    _currentPoseIndex = 0;
                    _error = null;
                  });
                },
                child: const Text('Enroll Another Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

